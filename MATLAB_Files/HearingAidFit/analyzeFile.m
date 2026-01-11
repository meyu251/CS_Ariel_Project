function [ result, matStruct,inputStruct ] = analyzeFile( varargin )
%ANALYZEFILE Summary of this function goes here
%   Detailed explanation goes here
[ cochleaConfig,inputStruct ] = preAnalyzeFile( varargin{:} );
% fprintf('ticcing...\n');
 tic;
% fprintf('processing...\n');
% figure(1);plot(cochleaConfig.Input_Signal,'r');hold on; plot(cochleaConfig.Input_Noise,'k'); hold off

[result, matStruct] = ProcessAudioLab(cochleaConfig);

%fprintf('process complete...\n');
%clear AudioLab;
if ( inputStruct.JND_Signal_Source )
    endTimer('run AudioLab analyzing %2$s for total duration %3$.1f on matlab at %1$.2f\n',inputStruct.filesStruct.tag_name,inputStruct.duration);
else
    endTimer('run AudioLab analyzing frequencies (%2$s) for total duration %3$.1f on matlab at %1$.2f\n',num2str(inputStruct.testedFrequencies),inputStruct.duration);
end
%  if ( hasFilledProp(cochleaConfig,'TEST_File_Target') )
%         twin = inputStruct.Test_Window;
%         if ( length(twin) == 1 )
%             figure(twin);
%         else
%             figure(twin(1));
%             subplot(twin(2),twin(3),twin(4));
%         end
%         [testVal, xx1,tx1] = read_bin_array( cochleaConfig.TEST_File_Target,cochleaConfig.Fs, 'float',256);
% %         for k=length(testedNoises):-1:1
% %             MeanRate(:,cmultiplier*3*(k-1)+cmultiplier*3) = [];
% %             MeanRate(:,cmultiplier*3*(k-1)+cmultiplier*2) = [];
% %             MeanRate(:,cmultiplier*3*(k-1)+cmultiplier) = [];
% %         end
%         %rp1 = toDB(rp1);
%         imagesc(tx1,xx1,testVal);
%         colorbar();
%     end
% creates text config for CLI version of this program (good for debugging
% and Nsight tests)

end

