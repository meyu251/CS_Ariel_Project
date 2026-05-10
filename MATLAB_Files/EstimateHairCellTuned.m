%EstimateHairCellTuned

clear all
Nsub=1;
Nf=8;  %number of tested frequencies
GetTunedAudiograms;
for sub=1:Nsub
     Audio(sub,:)=TunedAudiograms(sub,:); 
   

    [OHC0(sub) VecIHC(sub,:) cTs(sub,:) Gain(sub,:) OHCloss(sub,:)]= FindHCfromAudio(Audio(sub,:)',Nf);
    OHC0
end
%save HairCellEstimationTuned VecIHC OHC0 cTs  Gain OHCloss Audio 
PlotTunedResults