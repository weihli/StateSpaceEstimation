function [ diffToa ] = calculateDiffToa( xRaySources, earthEphemeris, sunEphemeris, spaceshipTrajectory )
% calculateDiffToa: calculate difference between 
% - time of arrrival to spacecraft
% and
% - time of arrival to ssb (solar system baricenter)
% for every x-ray source
% calculated by following expression:
%     dToa = (r+n*re)/c + tRel
% INPUT:
%       xRaySources          - array of x-ray sources (every item should be instance of the XRaySource);
%       earthEphemeris       - earth ephemeris (x, y, z - vectors in [km], vx, vy, vz - vectors in [km/sec]);
%       sunEphemeris         - sun ephemeris (x, y, z - vectors in [km], vx, vy, vz - vectors in [km/sec]);
%       spaceshipTrajectory  - state space vector of spaceship (array of 1-st, 2-nd, 3-d - trajectory coordinate vectors in [km]);
% OUTPUT:
%       diffToa              - array of differences between toa on spaceship and toa on ssb
%% ERROR CHECKING
    if (nargin ~= 4); error('[ toaRelativeEffects ] incorrect number of input arg. Should be 3'); end
%%
    c              = 299792.458; % speed of light [km/sec]  
    earthR         = [earthEphemeris.x earthEphemeris.y earthEphemeris.z];
    dimension      = length(xRaySources);
    [capacity, ~]  = size(spaceshipTrajectory);  
    tRel           = toaRelativeEffects(xRaySources, earthEphemeris, sunEphemeris, spaceshipTrajectory);
    
    diffToa = zeros(capacity, dimension);
    for i = 1:dimension        
        x = xRaySources(i);
        xNorm = repmat(x.Normal, capacity, 1);
        diffToa(:, i) = 1/c*(normOfEveryRow(spaceshipTrajectory) + dot(xNorm, earthR, 2)) + tRel(:, i);
    end
end