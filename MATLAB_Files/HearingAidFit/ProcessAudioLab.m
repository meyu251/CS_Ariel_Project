function [ result, matStruct] = ProcessAudioLab( configObject )
%PROCESSAUDIOLAB Summary of this function goes here
%   Detailed explanation goes here
matStruct = configObject.evaluatedMatStruct;
    result = AudioLabCM(matStruct);

end

