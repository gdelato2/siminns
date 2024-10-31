% CONSTRAINEDSAMPLING: Generate samples under specified constraints
%
% [table] = constrainedSampling(randomSamples, nominalLimts, constraintFun, priorityIdx)
%
% This function performs random sampling while ensuring that generated 
% samples meet given constraints and bounds.
% 
% Inputs:
%   randomSamples - Matrix of random samples (N x M), where N is 
%                   the number of samples and M is the number of
%                   parameters. The matrix can be generated with lhsdesign or
%                   any other DOE-like function. 
%   nominalLimits - Struct defining the nominal limits for each parameter,
%                   including their lower and upper bounds.
%   constraintFun - Function handle for any additional constraints that must
%                   be satisfied during sampling.
%   priorityIdx   - Index representing the parameter that should be 
%                   prioritized in the sampling process.
%
% Outputs:
%   table         - A table containing the generated samples, with each
%                   parameter as a column.
%
% Notes:
%   - The public release of this code does not support M > 5. 
%   - Please contact Gerardo De La Torre for unrestricted code.
