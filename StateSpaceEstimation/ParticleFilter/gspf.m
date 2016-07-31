function [estimate, dataSet, stateNoise, observNoise] = gspf(dataSet, stateNoise, observNoise, observation, control1, control2, model)
    % GSPF Gaussian Sum Particle Filter
    %
    %   The filter approximate the filtering and predictive distributions by weighted Gaussian mixtures and are basically
    %   banks of Gaussian particle filters. Then, we extend the use of Gaussian particle filters and Gaussian sum particle filters to
    %   dynamic state space (DSS) models with non-Gaussian noise. With non-Gaussian noise approximated by Gaussian mixtures, the non-Gaussian
    %   noise models are approximated by banks of Gaussian noise models, and Gaussian mixture filters are developed using
    %   algorithms developed for Gaussian noise DSS models
    %
    %   For more details please see:
    %   Jayesh H. Kotecha and Petar M. Djuric, "Gaussian Sum Particle Filtering for Dynamic State Space Models",
    %   Proceedings of ICASSP-2001, Salt Lake City, Utah, May 2001.
    %
    %   This filter assumes the following standard state-space model:
    %
    %     x(k) = f[x(k-1), v(k-1), U1(k-1)]
    %     z(k) = h[x(k), n(k), U2(k)]
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
    %         dataSet           particle filter data structure. Contains set of particles as well as their corresponding weights.
    %         stateNoise        process noise data structure
    %         observNoise       observation noise data structure
    %         observation       noisy observations starting at time k ( y(k),y(k+1),...,y(k+N-1) )
    %         control1          exogenous input to state transition function starting at time k-1 ( u1(k-1),u1(k),...,u1(k+N-2) )
    %         control2          exogenous input to state observation function starting at time k  ( u2(k),u2(k+1),...,u2(k+N-1) )
    %         gssModel          inference data structure.
    %
    %   OUTPUT
    %         estimate          state estimate generated from posterior distribution of state given all observation. Type of
    %                           estimate is specified by 'InferenceDS.estimateType'
    %         dataSet           updated Particle filter data structure. Contains set of particles as well as their corresponding weights.
    %         stateNoise        process noise data structure     (possibly updated)
    %         observNoise       observation noise data structure (possibly updated)
    %
    %   dataSet fields:
    %         .particlesNum        (scalar) number of particles
    %         .particles           (statedim-by-N matrix) particle buffer
    %         .weights             (1-by-N r-vector) particle weights
    %
    %   Required model fields:
    %         .estimateType        Estimate type : 'mean', 'mode', etc.
    %         .resampleThreshold   If the ratio of the 'effective particle set size' to the total number of particles
    %                              drop below this threshold  i.e.  (nEfective / particlesNum) < resampleThreshold
    %                              the particles will be resampled.  (nEfective is always less than or equal to particlesNum)
    %
    %% error checking
    if nargin ~= 7; error(' [ gspf ] Incorrect number of input arguments.'); end
    if ~ strcmp(stateNoise.noiseSourceType, 'gmm'); error(' [ gspf ] Process noise source must be of type : gmm (Gaussian Mixture Model)'); end
    if strcmp(dataSet.stateGMM.covarianceType, {'full','diag'}); error(' [ gspf ] state GMMs should have sqrt covariance types.'); end
    
    %%
    stateDim  = model.stateDimension;
    stateNoiseDim  = model.processNoiseDimension;
    num = dataSet.particlesNum;
    
    if (model.controlInputDimension == 0); control1 = []; end
    if (model.control2InputDimension == 0); control2 = []; end
    
    stateGMM = dataSet.stateGMM;
    mixtureCount  = stateGMM.mixtureCount * stateNoise.mixtureCount;
    
    sampleBuf1 = zeros(stateDim, num, mixtureCount);
    mixtureWeights = zeros(1, mixtureCount);
    sampleBuf2 = zeros(stateDim, num, mixtureCount);
    importanceWeights = zeros(mixtureCount, num);
    
    stateMeanPredict = zeros(stateDim, mixtureCount);
    stateCovPredict  = zeros(stateDim, stateDim, mixtureCount);
    
    %% time update
    % draw mixture samples from each state GMM component
    for i = 1 : stateNoise.mixtureCount
        xNoiseMean = cvecrep(stateNoise.mean(:, i), num);
        
        for j = 1 : stateGMM.mixtureCount
            k = j + (i-1)*stateGMM.mixtureCount;
            xNoise = stateNoise.covariance(:, :, i) * randn(stateNoiseDim, num) + xNoiseMean;
            xState = stateGMM.covariance(:, :, i) * randn(stateDim, num) + cvecrep(stateGMM.mean(:, i), num);
            sampleBuf1(:, :, k) = model.stateTransitionFun(model, xState, xNoise, control1);
            mixtureWeights(1, k) = stateGMM.weights(1, j) * stateNoise.weights(1, i);
        end
    end
    
    mixtureWeights = mixtureWeights / sum(mixtureWeights);
    
    % calculate predicted mean and covariance
    for i = 1:mixtureCount
        stateMeanPredict(:, i) = sum(sampleBuf1(:, :, i), 2) / num;
        [~, cov] = qr( (sampleBuf1(:, :, i) - cvecrep(stateMeanPredict(:, i), num))', 0 );
        stateCovPredict(:, :, i) = cov' / sqrt(num - 1);
    end
    
    %% measurement update
    % calculate observed samples and importance weights
    for i = 1:mixtureCount
        sampleBuf2(:, :, i) = stateCovPredict(:, :, i) * randn(stateDim, num) + cvecrep(stateMeanPredict(:, i), num);
        importanceWeights(i, :) = model.likelihoodStateFun(model, cvecrep(observation, num), sampleBuf2(:, :, i), control2, observNoise) + 1e-99;
    end
    
    weightNorm = 0;
    % calculate updated state mixture means, covariances, weights
    for i = 1:mixtureCount
        weight2 = importanceWeights(i, :);
        impWeightNorm = sum(weight2); % proabably weightFoo / sum(weightFoo)
        stateMeanPredict(:, i) = sum( rvecrep(weight2, stateDim) .* sampleBuf2(:, :, i), 2) / impWeightNorm;
        
        xCentered = ( rvecrep(sqrt(weight2), stateDim) ) .* ( sampleBuf2(:, :, i) - cvecrep(stateMeanPredict(:, i), num) );
        [~, covFoo] = qr(xCentered', 0);
        stateCovPredict(:, :, i) = covFoo' / sqrt(impWeightNorm);
        
        mixtureWeights(:, i) = mixtureWeights(:, i) * impWeightNorm;
        weightNorm = weightNorm + impWeightNorm;
    end
    
    mixtureWeights = mixtureWeights / weightNorm;
    mixtureWeights = mixtureWeights / sum(mixtureWeights);
    
    %% estimate
    if strcmp(model.estimateType, 'mean')
        estimate = sum(rvecrep(mixtureWeights, stateDim) .* stateMeanPredict, 2);
    else
        error(' [ gspf ] Unknown estimate type.');
    end
    
    %% resample
    resampleIdx = residualResample(1:mixtureCount, mixtureWeights);
    [~, idx] = sort(rand(1, mixtureCount));
    idx = idx(1:stateGMM.mixtureCount);
    idx = resampleIdx(idx);
    
    dataSet.stateGMM.mean = stateMeanPredict(:, idx);
    dataSet.stateGMM.covariance = stateCovPredict(:, :, idx);
    dataSet.stateGMM.weights = (1 / stateGMM.mixtureCount) * ones(1, stateGMM.mixtureCount);
end
