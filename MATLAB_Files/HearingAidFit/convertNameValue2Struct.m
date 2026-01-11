function [ result ] = convertNameValue2Struct( cellsArray )
%CONVERTNAMEVALUE2STRUCT Summary of this function goes here
%   Detailed explanation goes here
    fieldNames = cellsArray(1:2:end);
    values = cellsArray(2:2:end);
    result = struct;
    for i=1:length(fieldNames)
        result.(fieldNames{i}) = values{i};
    end
end

