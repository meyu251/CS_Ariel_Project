function [ literal ] = endTimer( message,varargin )
%ENDTIMER Summary of this function goes here
%   Detailed explanation goes here
    literal = sprintf(message,toc,varargin{:});
    disp(['endTimer: ' literal]);
end

