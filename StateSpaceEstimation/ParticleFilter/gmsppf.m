function [ estimate, dataSet, stateNoise, observNoise ] = gmsppf( dataSet, stateNoise, observNoise, observation, control1, control2, model)
    % gmsppf Gaussian Mixture Sigma-Point Particle Filter
    %
    %   Bayesian estimation algorithm that combines an importance sampling based measurement update step with a bank of
    %   Sigma-Point Kalman Filters for the time-update and proposal distribution generation. The posterior state density
    %   is represented by a Gaussian mixture model that is recovered from the weighted particle set of the measurement
    %   update step by means of a weighted EM algorithm. This step replaces the resampling stage needed by most
    %   particle filters and mitigates the sample depletion problem
    %
    %   For more details see:
    %       Rudolph van der Merwe Eric Wan, "GAUSSIAN MIXTURE SIGMA-POINT PARTICLE FILTERS FOR SEQUENTIAL PROBABILISTIC INFERENCE IN DYNAMIC STATE-SPACE MODELS"
    %       Conference Paper in Acoustics, Speech, and Signal Processing, 1988. ICASSP-88., 1988 International Conference on May 2003
    %
    %   [ estimate, dataSet, stateNoise, observNoise ] = gmsppf( dataSet, stateNoise, observNoise, observation, control1, control2, model)
    %
    %   This filter assumes the following standard state-space model:
    %
    %     x(k) = f[x(k-1), v(k-1), U1(k-1)]
    %     z(k) = h[x(k), n(k), U2(k)]
    %
    %   where:
    %       x is the system state;
    %       v the process noise;
    %       n the observation noise;
    %       u1 the exogenous input to the state;
    %       f the transition function;
    %       u2 the exogenous input to the state observation function;
    %       y the noisy observation of the system.
    %
    %   INPUT
    %         dataSet           particle filter data structure. Contains set of particles as well as their corresponding weights;
    %         stateNoise        process noise data structure;
    %         observNoise       observation noise data structure;
    %         observation       noisy observations starting at time k ( y(k),y(k+1),...,y(k+N-1) );
    %         control1          exogenous input to state transition function starting at time k-1 ( u1(k-1),u1(k),...,u1(k+N-2) );
    %         control2          exogenous input to state observation function starting at time k  ( u2(k),u2(k+1),...,u2(k+N-1) );
    %         model             inference data structure.
    %
    %   OUTPUT
    %         estimate          state estimate generated from posterior distribution of state given all observation. Type of
    %                           estimate is specified by 'model.estimateType';
    %         dataSet           updated Particle filter data structure. Contains set of particles as well as their corresponding weights;
    %         stateNoise        process noise data structure     (probably updated);
    %         observNoise       observation noise data structure (probably updated).
    %
    %   dataSet
    %       .particlesNum        number of particles to use;
    %       .stateGMM            Gaussian mixture model of state distribution with the following field:
    %       	.mixtureCount    number of mixture components in GMM;
    %           .mean            buffer of mean vectors (centroids) of state GMM components (statedim-by-M) ;
    %           .covariance   	 buffer of covariance matrices of state GMM components (statedim-by-statedim-my-M) ;
    %           .covarianceType  covariance matrix type ('full','sqrt','diag','swrt-diag') 'sqrt' is preferre;
    %           .weights         state GMM component weights (priors) (1-by-M).
    %
    %   Required model fields:
    %         .spkfType            (string) Type of SPKF to use (srukf or srcdkf).
    %         .estimateType        (string) Estimate type : 'mean', 'mode', etc.
    %
    %% error checking
    narginchk(7, 7);
    if ~strcmp(stateNoise.noiseSourceType, 'gmm'); error(' [ gmsppf ] Process noise source must be of type : gmm (Gaussian Mixture Model)'); end
    if ~strcmp(observNoise.noiseSourceType, 'gmm'); error(' [ gmsppf ] Observation noise source must be of type : gmm (Gaussian Mixture Model)'); end
    %%
    stateDim  = model.stateDimension;
    num = dataSet.particlesNum;
    
    stateGMM = dataSet.stateGMM;
    
    augmMixtCount  = stateGMM.mixtureCount*stateNoise.mixtureCount;
    fullMixtureCount = augmMixtCount*observNoise.mixtureCount;
    
    stateWeightPrior = zeros(1, augmMixtCount);
    stateMeanPrior   = zeros(stateDim, augmMixtCount);
    stateCovPrior    = zeros(stateDim, stateDim, augmMixtCount);
    
    stateWeightNew = zeros(1, fullMixtureCount);
    stateMeanNew   = zeros(stateDim, fullMixtureCount);
    stateCovNew    = zeros(stateDim, stateDim, fullMixtureCount);
    
    stateMean    = stateGMM.mean;
    stateCov     = stateGMM.covariance;
    stateWeights = stateGMM.weights;
    
    sateNoiseWeights  = stateNoise.weights;
    observNoiseWeights  = observNoise.weights;
    
    covarianceType = stateGMM.covarianceType;
    
    if ~strcmp(stateGMM.covarianceType, 'sqrt'); error(' [ gspf ] GSPF algorithm only support state GMMs ''sqrt'' covariance type.'); end
           
    if (model.controlInputDimension == 0); control1 = []; end
    if (model.control2InputDimension == 0); control2 = []; end
    
    normFactObser = (2*pi)^(model.observationDimension / 2);
    
    stateNoiseSPKF.mean = zeros(model.processNoiseDimension, 1);
    stateNoiseSPKF.covariance = zeros(model.processNoiseDimension);
    stateNoiseSPKF.adaptMethod = [];
    
    observNoiseSPKF.mean = zeros(model.observationNoiseDimension, 1);
    observNoiseSPKF.covariance = zeros(model.observationNoiseDimension);
    observNoiseSPKF.adaptMethod = [];
    
    switch model.spkfType
        case 'srukf'
            predict = @(x, s, xNoise, zNoise) srukf(x, s, xNoise, zNoise, observation, model, control1, control2);
        case 'sckf'
            predict = @(x, s, xNoise, zNoise) sckf(x, s, xNoise, zNoise, observation, model, control1, control2);
        case 'srcdkf'
            predict = @(x, s, xNoise, zNoise) srcdkf(x, s, xNoise, zNoise, observation, model, control1, control2);
        otherwise
            error('[ gmsppf ] Unknown inner filter type.');
    end
        
    %% time update
    for r = 1:observNoise.mixtureCount
        observNoiseSPKF.mean = observNoise.mean(:, r);
        observNoiseSPKF.covariance = observNoise.covariance(:, :, r);
        
        for k = 1:stateNoise.mixtureCount
            stateNoiseSPKF.mean  = stateNoise.mean(:, k);
            stateNoiseSPKF.covariance = stateNoise.covariance(:, :, k);
            
            for g = 1:stateGMM.mixtureCount            
                a = g + (k-1) * stateGMM.mixtureCount;
                j = a + (r-1) * augmMixtCount;
                
                [stateMeanNew(:, j), stateCovNew(:, :, j), stateNoiseSPKF, observNoiseSPKF, ds] = predict(stateMean(:, g), stateCov(:,:,g), stateNoiseSPKF, observNoiseSPKF);
                
                stateMeanPrior(:, a)   = ds.meanPredictedState;
                stateCovPrior(:, :, a) = ds.sqrtCovState;
                                                
                stateWeightPrior(1, a) = stateWeights(1, g)*sateNoiseWeights(1, k);
                
                sx1 = ds.sqrtObservCov \ ds.inov;
                sx2 = exp(-0.5*(sx1'*sx1)) / abs(normFactObser*prod(diag(ds.sqrtObservCov))) + 1e-99;
                
                stateWeightNew(1, j)   = stateWeightPrior(1, a)*observNoiseWeights(1, r) * sx2;                
            end
        end
    end
    
    stateWeightPrior = stateWeightPrior / sum(stateWeightPrior);
    stateWeightNew   = stateWeightNew / sum(stateWeightNew);
        
    %% measurement update
    priorStateGMM.covarianceType = stateGMM.covarianceType;
    priorStateGMM.mean = stateMeanPrior;
    priorStateGMM.covariance = stateCovPrior;
    priorStateGMM.weights = stateWeightPrior;
    priorStateGMM.dimension = stateDim;
    priorStateGMM.mixtureCount = augmMixtCount;
    
    newStateGMM.covarianceType = stateGMM.covarianceType;
    newStateGMM.mean = stateMeanNew;
    newStateGMM.covariance = stateCovNew;
    newStateGMM.weights = stateWeightNew; 
    newStateGMM.dimension = stateDim;
    newStateGMM.mixtureCount = fullMixtureCount;
    
    % Draw samples from the Gaussian Mixture proposal
    xSampleBuf = gmmSample(newStateGMM, num);
    
    % evaluate likelihood of each particle under the transition prior (have to average over distribution of X(k-1) )
    [~, ~, prior] = gmmProbability(priorStateGMM, xSampleBuf);
    
    % calculate observation likelihood for each particle
    likelihood = model.likelihoodStateFun(model, cvecrep(observation, num), xSampleBuf, control2, observNoise) + 1e-99;
    
    % evaluate likelihood of each particle under the proposal density
    [~, ~, proposal] = gmmProbability(newStateGMM, xSampleBuf);
    
    % calculate importance weights
    sampleW = (likelihood.*prior) ./ proposal;
    sampleW = sampleW ./ sum(sampleW);
    
    %% calculate estimate    
    if strcmp(model.estimateType, 'mean')
        estimate = xSampleBuf*sampleW';
    else
        error('[ gmsppf ] Unknown estimate type.');
    end
    
    %% resample    
%     outIndex  = residualResample(1:num, sampleW);
%     xSampleBuf = xSampleBuf(:, outIndex);
    sampleW = rvecrep(1/num, num);
    
    %% recover GMM representation of posterior distribution using EM    
    dataSet.particles = xSampleBuf;
    dataSet.weights = sampleW;    
    dataSet.stateGMM = gaussMixtureModelFit(xSampleBuf, stateGMM, [1e-5 1000], covarianceType, 1e-20);
end