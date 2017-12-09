function [ newState, newCovState, stateNoise, observNoise, internal ] = cqkf( state, covState, stateNoise, observNoise, observation, model, ctrl1, ctrl2)
    % cqkf. Cubature Quadrature Kalman Filter (some kind of High-degree Cubature Kalman Filter)
    %
    %   [ newState, newCovState, stateNoise, observNoise, internal ] = cqkf( state, covState, stateNoise, observNoise, observation, model, ctrl1, ctrl2)
    %
    %   This filter assumes the following standard state-space model:
    %
    %     x(k) = f[x(k-1), v(k-1), u1(k-1)];
    %     z(k) = h[x(k), n(k), u2(k)],
    %
    %   where
    %       x  - is the system state;
    %       v  - the process noise;
    %       n  - the observation noise;
    %       u1 - the exogenous input to the state;
    %       f  - transition function;
    %       u2 - the exogenous input to the state observation function;
    %       z  - the noisy observation of the system.
    %
    %   Cubature points calculated as intersection of unit hyper-sphere and its axes.
    %   Quadrature points calculated as solution of Chebyshev-Laguerre polynoms with order n' and a = (n / 2 - 1).
    %
    %   INPUT
    %         state        state mean at time k-1 ( x(k-1) );
    %         covState     square root factor of matrix through Singular Value Secomposition of state covariance at time k-1;
    %         stateNoise   process noise data structure (must be of type 'gaussian' or 'combo-gaussian');
    %         observNoise  observation noise data structure (must be of type 'gaussian' or 'combo-gaussian');
    %         observation  noisy observations at time k ( z(k) );
    %         model        inference data structure, which fully describes filtration issue (generated by inferenceDataGenerator function);
    %         control1     exogenous input to state transition function starting at time k-1 ( u1(k-1) );
    %         control2     exogenous input to state observation function starting at time k  ( u2(k) ).
    %
    %   OUTPUT
    %         newState                  estimates of state starting at time k ( E[x(t)|z(1), z(2), ..., z(t)] for t = k );
    %         newCovState               estimate of square root factor of matrix through Singular value decomposition of state covariance at time k;
    %         stateNoise                process noise data structure (possibly updated);
    %         observNoise               observation noise data structure (possibly updated);
    %         internal                 <<optional>> internal variables data structure
    %           .meanPredictedState        predicted state mean ( E[x(t)|z(1), z(2), ..., z(t-1)] for t = k );
    %           .stateCov                  predicted state covariance matrix at time k;
    %           .predictedObservMean       predicted observation ( E[z(k)|Z(k-1)] );
    %           .inov                      inovation signal;
    %           .observCov                 predicted of Cholesky factor of observation covariance;
    %           .filterGain                filter gain.
    %
    %% error checking
    if (nargin ~= 8 && nargin ~= 6)
        error('[ cqkf ] Not enough input arguments (should be 6 or 8).');
    end
    
    if (model.stateDimension ~= size(state, 1))
        error('[ cqkf ] Prior state dimension differs from model.stateDimension');
    end
    
    if (model.stateDimension ~= size(covState, 1))
        error('[ cqkf ] Prior state covariance dimension differs from model.stateDimension');
    end
    
    if (model.observationDimension ~= size(observation, 1));
        error('[ cqkf ] Observation dimension differs from model.observationDimension');
    end
    %%
    stateDim        = model.stateDimension;
    obsDim          = model.observationDimension;
    order           = model.cqkfParams(1);
    numCubPoints    = 2*stateDim*order;
    
    if (model.controlInputDimension == 0)
        ctrl1 = [];
    end
    if (model.control2InputDimension == 0)
        ctrl2 = [];
    end
    
    m_cubatureQuadraturePoints = memoize(@cubatureQuadraturePoints);
    [points, w] = m_cubatureQuadraturePoints(stateDim, order);
    w_x = rvecrep(w, stateDim);
    w_z = rvecrep(w, obsDim);
    
    %% calculate cubature points
    offsetPrediction = chol(covState, 'lower');
    cubatureSet  = cvecrep(state, numCubPoints) + offsetPrediction*points;
    
    %% propagate cubature-points through process model
    predictState = model.stateTransitionFun(model, cubatureSet, cvecrep(stateNoise.mean, numCubPoints), ctrl1);
    predictStateMean = predictState*w';
    
    centeredState = (predictState - cvecrep(predictStateMean, numCubPoints));
    predictedStateCov = w_x.*centeredState*centeredState' + stateNoise.covariance;
    
    %% calculate cubature points for measurement
    cubatureSet2 = cvecrep(predictStateMean, numCubPoints) + chol(predictedStateCov, 'lower')*points;
    
    %% propagate through observation model
    
    predictObs = model.stateObservationFun(model, cubatureSet2, cvecrep(observNoise.mean, numCubPoints), ctrl2);
    predictObsMean = predictObs*w';
    
    %% measurement update (correction)
    x = (cubatureSet2 - cvecrep(predictStateMean, numCubPoints));
    z = (predictObs - cvecrep(predictObsMean, numCubPoints));
    
    innovationCov = w_z.*z*z'+ observNoise.covariance;
    crossCov = w_x.*x*z';
    filterGain = crossCov*pinv(innovationCov);
    
    if isempty(model.innovationModelFunc)
        inov = observation - predictObsMean;
    else
        inov = model.innovationModelFunc( model, observation, predictObsMean);
    end
    
    newState = predictStateMean + filterGain * inov;
    newCovState = predictedStateCov - filterGain*innovationCov*filterGain';
    
    %% build additional ouptut param (required for debug)
    if nargout > 4
        internal.meanPredictedState    = predictStateMean;
        internal.stateCov              = predictedStateCov;
        internal.predictedObservMean   = predictObsMean;
        internal.inov                  = inov;
        internal.observCov             = innovationCov;
        internal.filterGain            = filterGain;
    end
end
