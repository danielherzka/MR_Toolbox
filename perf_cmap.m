function cmap = perf_cmap(N)

c = templateCmap;
templateN = size(c,1)-1;
idx_in = (0:templateN)./templateN;
idx_out = (0:(N-1))./(N-1);
R = interp1(idx_in, c(:,1), idx_out, 'linear')';
G = interp1(idx_in, c(:,2), idx_out, 'linear')';
B = interp1(idx_in, c(:,3), idx_out, 'linear')';

cmap = [R, G, B];

% if 1
%    
%     figure;
%     plot(idx_in,c(:,1),'r-x', 'markersize', 8);
%     hold on;
%     plot(idx_in,c(:,2),'g-x', 'markersize', 8);
%     plot(idx_in,c(:,3),'b-x', 'markersize', 8);
%     
%     plot(idx_out,R,'r-o', 'markersize', 3);
%     plot(idx_out,G,'g-o', 'markersize', 3);
%     plot(idx_out,B,'b-o', 'markersize', 3);
%     
% 
% end

function c = templateCmap

c = [...
                    0                   0                   0
   0.005268749780953   0.005268749780953   0.031250000000000
   0.010537499561906   0.010537499561906   0.062500000000000
   0.015806250274181   0.015806250274181   0.093750000000000
   0.021074999123812   0.021074999123812   0.125000000000000
   0.026343747973442   0.026343747973442   0.156250000000000
   0.031612500548363   0.031612500548363   0.187500000000000
   0.036881249397993   0.036881249397993   0.218750000000000
   0.042149998247623   0.042149998247623   0.250000000000000
   0.047418747097254   0.047418747097254   0.281250000000000
   0.052687495946884   0.052687495946884   0.312500000000000
   0.057956248521805   0.057956248521805   0.343750000000000
   0.063225001096725   0.063225001096725   0.375000000000000
   0.068493746221066   0.068493746221066   0.406250000000000
   0.073762498795986   0.073762498795986   0.437500000000000
   0.079031243920326   0.079031243920326   0.468750000000000
   0.084299996495247   0.084299996495247   0.500000000000000
   0.089568749070168   0.089568749070168   0.531250000000000
   0.094837494194508   0.094837494194508   0.562500000000000
   0.100106246769428   0.100106246769428   0.593750000000000
   0.105374991893768   0.105374991893768   0.625000000000000
   0.110643744468689   0.110643744468689   0.656250000000000
   0.115912497043610   0.115912497043610   0.687500000000000
   0.121181242167950   0.121181242167950   0.718750000000000
   0.126450002193451   0.126450002193451   0.750000000000000
   0.131718739867210   0.131718739867210   0.781250000000000
   0.136987492442131   0.136987492442131   0.812500000000000
   0.142256245017052   0.142256245017052   0.843750000000000
   0.147524997591972   0.147524997591972   0.875000000000000
   0.152793750166893   0.152793750166893   0.906250000000000
   0.158062487840652   0.158062487840652   0.937500000000000
   0.163331240415573   0.163331240415573   0.968750000000000
   0.168599992990494   0.168599992990494   1.000000000000000
   0.185920819640160   0.173279166221619   0.984395861625671
   0.203241661190987   0.177958324551582   0.968791663646698
   0.220562487840652   0.182637497782707   0.953187525272369
   0.237883329391479   0.187316656112671   0.937583327293396
   0.255204170942307   0.191995829343796   0.921979188919067
   0.272524982690811   0.196675002574921   0.906374990940094
   0.289845824241638   0.201354160904884   0.890770852565765
   0.307166665792465   0.206033334136009   0.875166654586792
   0.324487507343292   0.210712492465973   0.859562516212463
   0.341808319091797   0.215391665697098   0.843958318233490
   0.359129160642624   0.220070824027061   0.828354179859161
   0.376450002193451   0.224749997258186   0.812749981880188
   0.393770813941956   0.229429170489311   0.797145843505859
   0.411091655492783   0.234108328819275   0.781541645526886
   0.428412497043610   0.238787502050400   0.765937507152557
   0.445733338594437   0.243466660380363   0.750333309173584
   0.463054150342941   0.248145833611488   0.734729170799255
   0.480374991893768   0.252824991941452   0.719124972820282
   0.497695833444595   0.257504165172577   0.703520834445953
   0.515016674995422   0.262183338403702   0.687916636466980
   0.532337486743927   0.266862511634827   0.672312498092651
   0.549658358097076   0.271541655063629   0.656708300113678
   0.566979169845581   0.276220828294754   0.641104161739349
   0.584299981594086   0.280900001525879   0.625499963760376
   0.601620852947235   0.285579174757004   0.609895825386047
   0.618941664695740   0.290258347988129   0.594291687011719
   0.636262476444244   0.294937491416931   0.578687489032745
   0.653583347797394   0.299616664648056   0.563083350658417
   0.670904159545898   0.304295837879181   0.547479152679443
   0.688224971294403   0.308975011110306   0.531875014305115
   0.705545842647552   0.313654184341431   0.516270816326141
   0.722866654396057   0.318333327770233   0.500666677951813
   0.740187525749207   0.323012501001358   0.485062479972839
   0.757508337497711   0.327691674232483   0.469458311796188
   0.774829149246216   0.332370847463608   0.453854143619537
   0.792150020599365   0.337050020694733   0.438250005245209
   0.809470832347870   0.341729164123535   0.422645837068558
   0.826791644096375   0.346408337354660   0.407041668891907
   0.844112515449524   0.351087510585785   0.391437500715256
   0.861433327198029   0.355766683816910   0.375833332538605
   0.878754138946533   0.360445827245712   0.360229164361954
   0.896075010299683   0.365125000476837   0.344624996185303
   0.913395822048187   0.369804173707962   0.329020828008652
   0.930716693401337   0.374483346939087   0.313416659832001
   0.948037505149841   0.379162520170212   0.297812491655350
   0.965358316898346   0.383841663599014   0.282208323478699
   0.982679188251495   0.388520836830139   0.266604155302048
   1.000000000000000   0.393200010061264   0.250999987125397
   1.000000000000000   0.405841678380966   0.258024990558624
   1.000000000000000   0.418483346700668   0.265049993991852
   1.000000000000000   0.431125015020370   0.272074997425079
   1.000000000000000   0.443766683340073   0.279100000858307
   1.000000000000000   0.456408351659775   0.286124974489212
   1.000000000000000   0.469050019979477   0.293149977922440
   1.000000000000000   0.481691688299179   0.300174981355667
   1.000000000000000   0.494333326816559   0.307199984788895
   1.000000000000000   0.506974995136261   0.314224988222122
   1.000000000000000   0.519616663455963   0.321249991655350
   1.000000000000000   0.532258331775665   0.328274995088577
   1.000000000000000   0.544900000095367   0.335299968719482
   1.000000000000000   0.557541668415070   0.342324972152710
   1.000000000000000   0.570183336734772   0.349349975585938
   1.000000000000000   0.582825005054474   0.356374979019165
   1.000000000000000   0.595466673374176   0.363399982452393
   1.000000000000000   0.608108341693878   0.370424985885620
   1.000000000000000   0.620750010013580   0.377449989318848
   1.000000000000000   0.633391678333282   0.384474992752075
   1.000000000000000   0.646033346652985   0.391499996185303
   1.000000000000000   0.658675014972687   0.398524969816208
   1.000000000000000   0.671316683292389   0.405549973249435
   1.000000000000000   0.683958351612091   0.412574976682663
   1.000000000000000   0.696600019931793   0.419599980115891
   1.000000000000000   0.709241688251495   0.426624983549118
   1.000000000000000   0.721883356571198   0.433649986982346
   1.000000000000000   0.734525024890900   0.440674990415573
   1.000000000000000   0.747166693210602   0.447699964046478
   1.000000000000000   0.759808361530304   0.454724967479706
   1.000000000000000   0.772450029850006   0.461749970912933
   1.000000000000000   0.785091698169708   0.468774974346161
   1.000000000000000   0.797733306884766   0.475799977779388
   1.000000000000000   0.810374975204468   0.482824981212616
   1.000000000000000   0.823016643524170   0.489849984645844
   1.000000000000000   0.835658311843872   0.496874988079071
   1.000000000000000   0.848299980163574   0.503899991512299
   1.000000000000000   0.860941648483276   0.510924994945526
   1.000000000000000   0.873583316802979   0.517949998378754
   1.000000000000000   0.886224985122681   0.524975001811981
   1.000000000000000   0.898866653442383   0.531999945640564
   1.000000000000000   0.911508321762085   0.539024949073792
   1.000000000000000   0.924149990081787   0.546049952507019
   1.000000000000000   0.936791658401489   0.553074955940247
   1.000000000000000   0.949433326721191   0.560099959373474
   1.000000000000000   0.962074995040894   0.567124962806702
   1.000000000000000   0.974716663360596   0.574149966239929
   1.000000000000000   0.987358331680298   0.581174969673157
   1.000000000000000   1.000000000000000   0.588199973106384
   1.000000000000000   1.000000000000000   0.591442465782166
   1.000000000000000   1.000000000000000   0.594685018062592
   1.000000000000000   1.000000000000000   0.597927510738373
   1.000000000000000   1.000000000000000   0.601170063018799
   1.000000000000000   1.000000000000000   0.604412555694580
   1.000000000000000   1.000000000000000   0.607655107975006
   1.000000000000000   1.000000000000000   0.610897600650787
   1.000000000000000   1.000000000000000   0.614140152931213
   1.000000000000000   1.000000000000000   0.617382645606995
   1.000000000000000   1.000000000000000   0.620625197887421
   1.000000000000000   1.000000000000000   0.623867690563202
   1.000000000000000   1.000000000000000   0.627110183238983
   1.000000000000000   1.000000000000000   0.630352735519409
   1.000000000000000   1.000000000000000   0.633595228195190
   1.000000000000000   1.000000000000000   0.636837780475616
   1.000000000000000   1.000000000000000   0.640080273151398
   1.000000000000000   1.000000000000000   0.643322825431824
   1.000000000000000   1.000000000000000   0.646565318107605
   1.000000000000000   1.000000000000000   0.649807870388031
   1.000000000000000   1.000000000000000   0.653050363063812
   1.000000000000000   1.000000000000000   0.656292915344238
   1.000000000000000   1.000000000000000   0.659535408020020
   1.000000000000000   1.000000000000000   0.662777960300446
   1.000000000000000   1.000000000000000   0.666020452976227
   1.000000000000000   1.000000000000000   0.669262945652008
   1.000000000000000   1.000000000000000   0.672505497932434
   1.000000000000000   1.000000000000000   0.675747990608215
   1.000000000000000   1.000000000000000   0.678990542888641
   1.000000000000000   1.000000000000000   0.682233035564423
   1.000000000000000   1.000000000000000   0.685475587844849
   1.000000000000000   1.000000000000000   0.688718080520630
   1.000000000000000   1.000000000000000   0.691960632801056
   1.000000000000000   1.000000000000000   0.695203125476837
   1.000000000000000   1.000000000000000   0.698445677757263
   1.000000000000000   1.000000000000000   0.701688170433044
   1.000000000000000   1.000000000000000   0.704930663108826
   1.000000000000000   1.000000000000000   0.708173215389252
   1.000000000000000   1.000000000000000   0.711415708065033
   1.000000000000000   1.000000000000000   0.714658260345459
   1.000000000000000   1.000000000000000   0.717900753021240
   1.000000000000000   1.000000000000000   0.721143305301666
   1.000000000000000   1.000000000000000   0.724385797977448
   1.000000000000000   1.000000000000000   0.727628350257874
   1.000000000000000   1.000000000000000   0.730870842933655
   1.000000000000000   1.000000000000000   0.734113395214081
   1.000000000000000   1.000000000000000   0.737355887889862
   1.000000000000000   1.000000000000000   0.740598380565643
   1.000000000000000   1.000000000000000   0.743840932846069
   1.000000000000000   1.000000000000000   0.747083425521851
   1.000000000000000   1.000000000000000   0.750325977802277
   1.000000000000000   1.000000000000000   0.753568470478058
   1.000000000000000   1.000000000000000   0.756811022758484
   1.000000000000000   1.000000000000000   0.760053515434265
   1.000000000000000   1.000000000000000   0.763296067714691
   1.000000000000000   1.000000000000000   0.766538560390472
   1.000000000000000   1.000000000000000   0.769781112670898
   1.000000000000000   1.000000000000000   0.773023605346680
   1.000000000000000   1.000000000000000   0.776266098022461
   1.000000000000000   1.000000000000000   0.779508650302887
   1.000000000000000   1.000000000000000   0.782751142978668
   1.000000000000000   1.000000000000000   0.785993695259094
   1.000000000000000   1.000000000000000   0.789236187934875
   1.000000000000000   1.000000000000000   0.792478740215302
   1.000000000000000   1.000000000000000   0.795721232891083
   1.000000000000000   1.000000000000000   0.798963785171509
   1.000000000000000   1.000000000000000   0.802206277847290
   1.000000000000000   1.000000000000000   0.805448830127716
   1.000000000000000   1.000000000000000   0.808691322803497
   1.000000000000000   1.000000000000000   0.811933875083923
   1.000000000000000   1.000000000000000   0.815176367759705
   1.000000000000000   1.000000000000000   0.818418860435486
   1.000000000000000   1.000000000000000   0.821661412715912
   1.000000000000000   1.000000000000000   0.824903905391693
   1.000000000000000   1.000000000000000   0.828146457672119
   1.000000000000000   1.000000000000000   0.831388950347900
   1.000000000000000   1.000000000000000   0.834631502628326
   1.000000000000000   1.000000000000000   0.837873995304108
   1.000000000000000   1.000000000000000   0.841116547584534
   1.000000000000000   1.000000000000000   0.844359040260315
   1.000000000000000   1.000000000000000   0.847601592540741
   1.000000000000000   1.000000000000000   0.850844085216522
   1.000000000000000   1.000000000000000   0.854086577892303
   1.000000000000000   1.000000000000000   0.857329130172729
   1.000000000000000   1.000000000000000   0.860571622848511
   1.000000000000000   1.000000000000000   0.863814175128937
   1.000000000000000   1.000000000000000   0.867056667804718
   1.000000000000000   1.000000000000000   0.870299220085144
   1.000000000000000   1.000000000000000   0.873541712760925
   1.000000000000000   1.000000000000000   0.876784265041351
   1.000000000000000   1.000000000000000   0.880026757717133
   1.000000000000000   1.000000000000000   0.883269309997559
   1.000000000000000   1.000000000000000   0.886511802673340
   1.000000000000000   1.000000000000000   0.889754295349121
   1.000000000000000   1.000000000000000   0.892996847629547
   1.000000000000000   1.000000000000000   0.896239340305328
   1.000000000000000   1.000000000000000   0.899481892585754
   1.000000000000000   1.000000000000000   0.902724385261536
   1.000000000000000   1.000000000000000   0.905966937541962
   1.000000000000000   1.000000000000000   0.909209430217743
   1.000000000000000   1.000000000000000   0.912451982498169
   1.000000000000000   1.000000000000000   0.915694475173950
   1.000000000000000   1.000000000000000   0.918937027454376
   1.000000000000000   1.000000000000000   0.922179520130157
   1.000000000000000   1.000000000000000   0.925422012805939
   1.000000000000000   1.000000000000000   0.928664565086365
   1.000000000000000   1.000000000000000   0.931907057762146
   1.000000000000000   1.000000000000000   0.935149610042572
   1.000000000000000   1.000000000000000   0.938392102718353
   1.000000000000000   1.000000000000000   0.941634654998779
   1.000000000000000   1.000000000000000   0.944877147674561
   1.000000000000000   1.000000000000000   0.948119699954987
   1.000000000000000   1.000000000000000   0.951362192630768
   1.000000000000000   1.000000000000000   0.954604744911194
   1.000000000000000   1.000000000000000   0.957847237586975
   1.000000000000000   1.000000000000000   0.961089789867401
   1.000000000000000   1.000000000000000   0.964332282543182
   1.000000000000000   1.000000000000000   0.967574775218964
   1.000000000000000   1.000000000000000   0.970817327499390
   1.000000000000000   1.000000000000000   0.974059820175171
   1.000000000000000   1.000000000000000   0.977302372455597
   1.000000000000000   1.000000000000000   0.980544865131378
   1.000000000000000   1.000000000000000   0.983787417411804
   1.000000000000000   1.000000000000000   0.987029910087585
   1.000000000000000   1.000000000000000   0.990272462368011
   1.000000000000000   1.000000000000000   0.993514955043793
   1.000000000000000   1.000000000000000   0.996757507324219
   1.000000000000000   1.000000000000000   1.000000000000000
   ];