function [ estimate, dataSet, stateNoise, observNoise ] = sppf( dataSet, stateNoise, observNoise, observation, control1, control2, model )
    % sppf. Sigma-Point Particle Filter.
    %
    %   This hybrid particle filter uses a sigma-point Kalman filter (SRUKF, SRCDKF) or Cubature Kalman filter (SCKF) for proposal distribution generation
    %   and is an extension of the original "Unscented Particle Filter".
    %
    %   [ estimate, dataSet, stateNoise, observNoise ] = sppf( dataSet, stateNoise, observNoise, observation, control1, control2, model )
    %
    %   This filter assumes the following standard state-space model:
    %
    %     x(k) = f[x(k-1), v(k-1), u1(k-1)];
    %     z(k) = h[x(k), n(k), u2(k)],
    %
    %   where:
    %       x   is the system state;
    %       v   the process noise;
    %       n   the observation noise;
    %       u1  the exogenous input to the state;
    %       f   the transition function;
    %       u2  the exogenous input to the state observation function;
    %       z   the noisy observation of the system.
    %
    %   INPUT
    %         dataSet           particle filter data structure. Contains set of particles as well as their corresponding weights;
    %         stateNoise        process noise data structure;
    %         observNoise       observation noise data structure;
    %         observation       noisy observations at time k ( z(k) );
    %         control1          exogenous input to state transition function at time k-1 ( u1(k-1) )
    %         control2          exogenous input to state observation function at time k ( u2(k) );
    %         model             inference data structure, which fully describes filtration issue (generated by inference_model_generator function).
    %
    %   OUTPUT
    %         estimate          state estimate generated from posterior distribution of state given all observation;
    %         dataSet           updated Particle filter data structure (contains set of particles as well as their corresponding weights);
    %         stateNoise        process noise data structure (possibly updated);
    %         observNoise       observation noise data structure (possibly updated).
    %
    %   dataSet fields:
    %         .particlesNum     number of particles;
    %         .particles        particle buffer (statedim-by-N matrix);
    %         .weights          particle weights (1-by-N r-vector).
    %
    %   Required gssModel fields:
    %         .estimateType        estimate type : 'mean', 'mode', etc;
    %         .resampleThreshold   if the ratio of the 'effective particle set size' to the total number of particles
    %                              drop below this threshold  i.e.  (nEfective / particlesNum) < resampleThreshold
    %                              the particles will be resampled.  (nEfective is always less than or equal to particlesNum).
    %%
    narginchk(7, 7);
    
    if ~string_match(dataSet.processNoise.covarianceType, {'sqrt', 'sqrt-diag'})
        error('[ sppf ] SPPF algorithm only support state noise (spkf component) with ''sqrt'' and ''sqrt-diag'' covariance types.');
    end
    
    if ~string_match(dataSet.observationNoise.covarianceType, {'sqrt', 'sqrt-diag'})
        error('[ sppf ] SPPF algorithm only support observation (spkf component) noise with ''sqrt'' and ''sqrt-diag'' covariance types.');
    end
    %%
    num  = dataSet.particlesNum;
    
    stateDim        = model.stateDimension;
    x               = dataSet.particles;
    sqrtCov         = dataSet.particlesCov;
    procNoiseSpkf   = dataSet.processNoise;
    obsNoiseSpkf    = dataSet.observationNoise;
    weights         = dataSet.weights;
    
    if (model.controlInputDimension == 0)
        control1 = [];
    end
    
    if (model.control2InputDimension == 0)
        control2 = [];
    end
    
    sqrtCovPred  = zeros(stateDim, stateDim, num);
    xNew    = zeros(stateDim, num);
    xPred   = zeros(stateDim, num);
    
    ones_numP = ones(num, 1);
    ones_Xdim = ones(1, stateDim);
    
    proposal = zeros(1, num);
    normfact = (2*pi) ^ (stateDim/2);
    obs = observation(:, ones_numP);
    
    %% Time update (prediction step)
    randBuf = randn(stateDim, num);
    
    switch model.spkfType
        case 'srukf'
            for k = 1 : num
                [xNew(:, k), sqrtCovPred(:, :, k), procNoiseSpkf, obsNoiseSpkf, ~] = srukf(x(:, k), sqrtCov(:, :, k), procNoiseSpkf, obsNoiseSpkf, ...
                    observation, model, control1, control2);
                xPred(:, k) = xNew(:, k) + sqrtCovPred(:, :, k) * randBuf(:, k);
            end
        case 'srcdkf'
            for k = 1 : num
                [xNew(:, k), sqrtCovPred(:, :, k), procNoiseSpkf, obsNoiseSpkf, ~] = srcdkf(x(:, k), sqrtCov(:, :, k), procNoiseSpkf, obsNoiseSpkf, ...
                    observation, model, control1, control2);
                xPred(:, k) = xNew(:, k) + sqrtCovPred(:, :, k) * randBuf(:, k);
            end
        case 'sckf'
            for k = 1 : num
                [xNew(:, k), sqrtCovPred(:, :, k), procNoiseSpkf, obsNoiseSpkf, ~] = sckf(x(:, k), sqrtCov(:, :, k), procNoiseSpkf, obsNoiseSpkf, ...
                    observation, model, control1, control2);
                xPred(:, k) = xNew(:, k) + sqrtCovPred(:, :, k) * randBuf(:, k);
            end
        otherwise
            error(' [ sppf ] Unknown SPKF type.');
    end
    
    %% Evaluate importance weights
    % calculate transition prior for each particle (in log domain)
    prior = model.prior( model, xPred, x, control1, stateNoise) + 1e-99;
    
    % calculate observation likelihood for each particle (in log domain)
    likelihood = model.likelihood(model, obs, xPred, control2, observNoise) + 1e-99;
    
    difX = xPred - xNew;
    for k = 1 : num
        cholFact = sqrtCovPred(:, :, k);
        foo = cholFact \ difX(:, k);
        proposal(k) = exp(-0.5*(foo'*foo)) / abs(normfact*prod(diag(cholFact))) + 1e-99;
        weights(k) = weights(k) * likelihood(k) * prior(k) / proposal(k);
    end
    
    weights = weights / sum(weights);
    
    %% Calculate estimate
    if strcmp(model.estimateType, 'mean')
        estimate = sum(weights(ones_Xdim, :) .* xPred, 2);
    else
        error(' [ sppf ] Unknown estimate type.');
    end
    
    %% Resample
    effSetSize = 1 / sum(weights.^2);
    
    if effSetSize < round(num * model.resampleThreshold)
        outIndex = resample(model.resampleMethod, weights, num);
        x = xPred(:, outIndex);
        
        for k = 1 : num
            sqrtCov(:, :, k) = sqrtCovPred(:, :, outIndex(k));
        end
        
        weights = column_vector_replicate(1 / num, num);
    else
        x  = xPred;
        sqrtCov = sqrtCovPred;
    end
        
    dataSet.particles           = x;
    dataSet.particlesCov        = sqrtCov;
    dataSet.weights             = weights;
    dataSet.processNoise        = procNoiseSpkf;
    dataSet.observationNoise    = obsNoiseSpkf;
end
