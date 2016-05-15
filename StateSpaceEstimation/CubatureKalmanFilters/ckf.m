function [newState, newCovState, processNoise, observationNoise, internalVariables] = ckf(state, covState, processNoise, observationNoise, observation, gssModel, controlProcess, controlObservation)
% CKF  Cubature Kalman Filter (subclass of Sigma Point Kalman Filter)
%
%   [newState, newCovState, processNoise, observationNoise, internalVariables] = ckf(state, covState, processNoise, observationNoise, observation, controlProcess, controlObservation, inferenceDataSet)
%
%   This filter assumes the following standard state-space model:
%
%     x(k) = f[x(k-1), v(k-1), U1(k-1)]
%     y(k) = h[x(k), n(k), U2(k)]
%
%   where:
%       x is the system state,
%       v the process noise,
%       n the observation noise,
%       u1 the exogenous input to the state
%       f the transition function,
%       u2 the exogenous input to the state observation function
%       y the noisy observation of the system.
%
%   INPUT
%         state                  state mean at time k-1          ( xh(k-1) )
%         covState               state covariance at time k-1    ( Px(k-1) )
%         processNoise           process noise data structure     (must be of type 'gaussian' or 'combo-gaussian')
%         observationNoise       observation noise data structure (must be of type 'gaussian' or 'combo-gaussian')
%         observation            noisy observations starting at time k ( y(k),y(k+1),...,y(k+N-1) )
%         controlProcess         exogenous input to state transition function starting at time k-1 ( u1(k-1),u1(k),...,u1(k+N-2) )
%         controlObservation     exogenous input to state observation function starting at time k  ( u2(k),u2(k+1),...,u2(k+N-1) )
%         inferenceDataSet       inference data structure generated by GENINFDS function.
%
%   OUTPUT
%         newState               estimates of state starting at time k ( E[x(t)|y(1),y(2),...,y(t)] for t=k,k+1,...,k+N-1 )
%         newState               state covariance
%         processNoise           process noise data structure     (possibly updated)
%         observationNoise       observation noise data structure (possibly updated)
%
%         internalVariables             <<optional>> internal variables data structure
%           .meanPredictedState         	predicted state mean ( E[x(t)|y(1),y(2),..y(t-1)] for t=k,k+1,...,k+N-1 )
%           .predictedStateCov              predicted state covariance
%           .predictedObservMean            predicted observation ( E[y(k)|Y(k-1)] )
%           .inov                           inovation signal
%           .predictedObservCov             inovation covariance
%           .filterGain                     Kalman gain
%
    %% ERROR CHECKING
    if (nargin ~= 8 && nargin ~= 6); error(' [ ckf ] Not enough input arguments (should be 6 or 8).'); end

    if (gssModel.stateDimension ~= size(state, 1)); error('[ ckf ] Prior state dimension differs from inferenceDataSet.stateDimension'); end

    if (gssModel.stateDimension ~= size(covState, 1)); error('[ ckf ] Prior state covariance dimension differs from inferenceDataSet.stateDimension'); end

    if (gssModel.observationDimension ~= size(observation, 1)); error('[ ckf ] Observation dimension differs from inferenceDataSet.observationDimension'); end

    %%
    stateDim         = gssModel.stateDimension;
    procNoiseDim     = gssModel.processNoiseDimension;
    obsNoiseDim      = gssModel.observationNoiseDimension;
    observDim        = gssModel.observationDimension;
    
    augmentDim = stateDim + procNoiseDim;
    numCubPointSet1 = 2*augmentDim;

    if (gssModel.controlInputDimension == 0); controlProcess = zeros(0, numCubPointSet1); end
    
    %% Calculate cubature points
    if (procNoiseDim ~= 0)
        offsetPrediction = [svdDecomposition(covState) zeros(stateDim, procNoiseDim); zeros(procNoiseDim, stateDim) svdDecomposition(processNoise.covariance)];
        cubatureSet  = cvecrep([state; processNoise.mean], numCubPointSet1) + offsetPrediction*(sqrt(numCubPointSet1/2)*[eye(augmentDim) -eye(augmentDim)]);
    else
        offsetPrediction = svdDecomposition(covState);
        cubatureSet  = cvecrep(state, numCubPointSet1) + offsetPrediction*(sqrt(numCubPointSet1/2)*[eye(augmentDim) -eye(augmentDim)]);
    end   

    %% Propagate sigma-points through process model
    predictedState = zeros(stateDim, numCubPointSet1);
    for i = 1:numCubPointSet1
        predictedState(:, i) = gssModel.stateTransitionFun(gssModel, cubatureSet(1:stateDim, i), cubatureSet(stateDim+1 : stateDim + procNoiseDim, i), controlProcess(:, i));
    end

    predictedStateMean = sum(predictedState, 2) / numCubPointSet1;
    squareRootPredictedStateCov = (predictedState - cvecrep(predictedStateMean, numCubPointSet1)) / sqrt(numCubPointSet1);
    predictedStateCov = squareRootPredictedStateCov*squareRootPredictedStateCov'; % probably + processNoiseCov

    %% Calculate cubature points for measurement
    augmentDim = stateDim + obsNoiseDim;
    numCubPointSet2 = 2*augmentDim;
    offsetObs = [svdDecomposition(predictedStateCov) zeros(stateDim, obsNoiseDim); zeros(obsNoiseDim, stateDim) svdDecomposition(observationNoise.covariance)];
    cubatureSet2 = cvecrep([predictedStateMean; observationNoise.mean], numCubPointSet2) + offsetObs*(sqrt(numCubPointSet2/2)*[eye(augmentDim) -eye(augmentDim)]);

    %% Propagate through observation model
    if (gssModel.control2InputDimension == 0); controlObservation = zeros(0, numCubPointSet2); end
    predictedObs = zeros(observDim, numCubPointSet2);
    for i = 1:numCubPointSet2
        predictedObs(:, i) = gssModel.stateObservationFun(gssModel, cubatureSet2(1:stateDim, i), cubatureSet2(stateDim+1:stateDim+obsNoiseDim, i), controlObservation(:, i));
    end

    predictedObsMean = sum(predictedObs, 2) / numCubPointSet2;

    %% Measurement update
    x = (cubatureSet2(1:stateDim, :)-cvecrep(predictedStateMean, numCubPointSet2)) / sqrt(numCubPointSet2);
    z = (predictedObs-cvecrep(predictedObsMean, numCubPointSet2)) / sqrt(numCubPointSet2);

    innovationCov = z*z'+ observationNoise.covariance;
    crossCov = x*z';
    filterGain = crossCov*pinv(innovationCov);

    if isempty(gssModel.innovationModelFunc)
        inov = observation - predictedObsMean;
    else
        inov = gssModel.innovationModelFunc( gssModel, observation, predictedObsMean);
    end

    newState = predictedStateMean + filterGain*inov;
    newCovState = predictedStateCov - filterGain*innovationCov*filterGain';

    %% additional ouptut param (required for debug)
    internalVariables.meanPredictedState    = predictedStateMean;
    internalVariables.predictedStateCov     = predictedStateCov;
    internalVariables.predictedObservMean   = predictedObsMean;
    internalVariables.inov                  = inov;
    internalVariables.predictedObservCov    = innovationCov;
    internalVariables.filterGain            = filterGain;
end