%PlotTunedResults

x=0:3.5/256:3.5-3.5/256;
load Parabolicfit
[Egt, at bt, ct]=fitParabola(IH,mIH,mGa); 

load  TunedData
for sub=1:10
    figure(sub)
    Audiogram=TunedAudiograms(sub,:);
    JND=Ethreshold(sub,:);
    OHC_Vector=OHCindex(sub);
    IHC_Vector=IHCindex(sub,:);
    if mod(sub, 2) == 1 
        Ear='R';
    else
        Ear='L';
    end
    t = tiledlayout(2,2);
%t.TileSpacing = 'compact';
%t.Padding = 'compact';

%subplot(5,1,[1,2])
    t1=nexttile;  %([2 1]);
    semilogx(TestFreq,-Audiogram,'ro','LineWidth',2) 
    hold on
    semilogx(TestFreq,-JND,'k','LineWidth',2)
    title([' Sub ', num2str(round(sub/2)), Ear])

    xlabel('Frequency (kHz)' , 'FontSize',12)
    ylabel('Hearing Loss(dB)','FontSize',12)
    axis([220 9000 -105 15])
    t1.YTick=[-100,-75,-50,-25, 0];
    t1.YTickLabel=[100 , 75, 50, 25, 0];
    t1.XTick=[500 1000 2000 4000 8000];
    t1.XTickLabel=[0.5, 1, 2, 4, 8];
%title(['Age ' num2str(Ages(j))])
    legend('Measured','Simulated Audiogram',...
    'Location','NorthWest')

%text(300,10,['MSE= ' num2str(MSE) ' dB']);
%axis([0 6000 0 120])



%subplot(5,1,[1,2])
    t5=nexttile; %([2 1]);
    semilogx(TestFreq,Gain(sub,:),'k--','LineWidth',2) 
    title('Inner Hair Cell Loss')
    xlabel('Frequency (kHz)','FontSize',12)
    ylabel('IHC Loss(dB)','FontSize',12)
    axis([220 9000 0 90])
    t5.YTick=[0, 25, 50, 75];
    t5.YTickLabel=[0, 25, 50, 75];
    t5.XTick=[500 1000 2000 4000 8000];
    t5.XTickLabel=[0.5, 1, 2, 4, 8];
%title(['Age ' num2str(Ages(j))])


    pX=flip([x x(256) x(1)]);
    OHC0=100*OHC_Vector/0.5;
    IHC0=IHC_Vector;
    PrIHC0=real((-bt)+sqrt(bt^2-4*at*(ct-IHC0))./(2*at));
    pOHC=flip([ OHC0*ones(1,256) 0 0]);
    pIHC=flip([PrIHC0 0 0]);

    g2=nexttile;
%subplot(5,1,4); 
    fill(pX,pIHC,'b'); axis([ 0 3.5 0 100]); box off
    title('IHC')
    ylabel('%','FontSize',12)
     xlabel('Distance from Base [cm]','FontSize',12)
    g3=nexttile;
%subplot(5,1,5); 
%fill(pX,pOHC,'g'); axis([0 3.5 0 100]);box off
    bar(OHC0,'g')
    title('OHC Index')
    ylim([0,100]);
    g3.XTick=[];
    g3.XTickLabel=[];
%xlabel('Distance from Stapes [cm]','FontSize',16)
%ylabel('%OHC','FontSize',16)
end
