function Plot_p(varargin)

Para=inputParser;

addOptional(Para,'eta0',0.59);
addOptional(Para,'d0',10^(-2));
addOptional(Para,'Q',0.002);
addOptional(Para,'P',0.99);
addOptional(Para,'pmin',0.86);
addOptional(Para,'pmax',1.0);
addOptional(Para,'pstep',0.03);
addOptional(Para,'dig',32);
addOptional(Para,'nk',[5,2;5,2;5,2;5,2;5,2;5,2;5,2;5,2]);
addOptional(Para, 'SavePath', '', @(x)ischar(x) || isstring(x));
addOptional(Para, 'DEName', '', @(x)ischar(x) || isstring(x));
addOptional(Para, 'DCRName', '', @(x)ischar(x) || isstring(x));

parse(Para,varargin{:});

eta0=Para.Results.eta0;
d0=Para.Results.d0;
Q=Para.Results.Q;
P=Para.Results.P;
pmin=Para.Results.pmin;
pmax=Para.Results.pmax;
pstep=Para.Results.pstep;
nk=Para.Results.nk;
dig=Para.Results.dig;
SavePath=Para.Results.SavePath;
DEName=Para.Results.DEName;
DCRName=Para.Results.DCRName;

L=size(pmin:pstep:pmax,2);
N=size(nk,1)+1;
list_eta=zeros(L,N);
list_d=zeros(L,N);
list_name = strings(L, 1);

for l=1:L
    Data=Calculate_eta_d('eta0',eta0,'d0',d0,'P',P,'Q',Q,'p1',pmin+pstep*(l-1),'nk',nk,'dig',dig);
    list_eta(l,:)=vpa(Data(:,1).',dig);
    list_d(l,:)=vpa(Data(:,2).',dig);
    fprintf('\n');
    fprintf('p=%.2f, Level %d, Initialized [DE,DCR]=[%.2f%%, %.1e]\n', pmin+pstep*(l-1), 0, Data(1,1)*100, Data(1,2));
    for level =1:N-1
        fprintf('p=%.2f, Level %d, [n,k]=[%d, %d], [DE,DCR]=[%.1f%%, %.1e]\n', pmin+pstep*(l-1), level, nk(level,1),nk(level,2),Data(level+1,1)*100, Data(level+1,2));
    end
    list_name(l)="p= " +(pmin+pstep*(l-1));
end

Plot(list_eta,'list_name',list_name,'Save',SavePath+DEName,'Y_Label','$\eta$','Title','Detective Efficiency vs. $p$','y_range',[min(list_eta(:))-0.05 max(list_eta(:))+0.05])
Plot(list_d,'list_name',list_name,'Save',SavePath+DCRName,'Y_Label','$d$','Y_Scale','log','Title','Dark Count Rate vs. $p$','y_range',[min(list_d(:))/10 1])

end