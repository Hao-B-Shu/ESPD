function Main(varargin)

Para=inputParser;

addOptional(Para,'eta0',0.59);
addOptional(Para,'d0',10^(-2));
addOptional(Para,'Q',0.002);
addOptional(Para,'P',0.99);
addOptional(Para,'p1',0.99);
addOptional(Para,'dig',32);
addOptional(Para,'nk',{[8,2;8,4;8,4;8,4;8,4;8,4;8,4]});
addOptional(Para,'nk_name',[]);
addOptional(Para, 'SavePath', '', @(x)ischar(x) || isstring(x));
addOptional(Para, 'DEName', '', @(x)ischar(x) || isstring(x));
addOptional(Para, 'DCRName', '', @(x)ischar(x) || isstring(x));

parse(Para,varargin{:});

eta0=Para.Results.eta0;
d0=Para.Results.d0;
Q=Para.Results.Q;
P=Para.Results.P;
p1=Para.Results.p1;
nk=Para.Results.nk;
nk_name=Para.Results.nk_name;
dig=Para.Results.dig;
SavePath=Para.Results.SavePath;
DEName=Para.Results.DEName;
DCRName=Para.Results.DCRName;

L=length(nk);
N=size(nk{1},1)+1;
list_eta=zeros(L,N);
list_d=zeros(L,N);

if isempty(nk_name)
    nk_name = arrayfun(@(x) sprintf('Para %d', x), 1:length(nk), 'UniformOutput', false);
end

for l=1:L
    Data=Calculate_eta_d('eta0',eta0,'d0',d0,'P',P,'Q',Q,'p1',p1,'nk',nk{l},'dig',dig);
    list_eta(l,:)=vpa(Data(:,1).',dig);
    list_d(l,:)=vpa(Data(:,2).',dig);
    fprintf('\n');
    fprintf('Level %d, Initialized [DE,DCR]=[%.2f%%, %.1e]\n', 0, Data(1,1)*100, Data(1,2));
    for level =1:N-1
        fprintf('Level %d, [n,k]=[%d, %d], [DE,DCR]=[%.1f%%, %.1e]\n', level, nk{l}(level,1),nk{l}(level,2),Data(level+1,1)*100, Data(level+1,2));
    end
end

Plot(list_eta,'list_name',nk_name+": DE",'Save',SavePath+DEName,'Y_Label','$\eta$','Title','Detective Efficiency vs Level','y_range',[min(list_eta(:)) 1])
Plot(list_d,'list_name',nk_name+": DCR",'Save',SavePath+DCRName,'Y_Label','$d$','Y_Scale','log','Title','Dark Count Rate vs Level','y_range',[min(list_d(:))/10 1])

end