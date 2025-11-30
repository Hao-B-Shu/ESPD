function data=Calculate_eta_d(varargin)

Para=inputParser;
addOptional(Para,'nk',[8,2;8,4;8,4;8,4;8,4;8,4;8,4]);
addOptional(Para,'P',0.99);
addOptional(Para,'p1',0.99);
addOptional(Para,'eta0',0.59);
addOptional(Para,'d0',10^(-2));
addOptional(Para,'Q',0.002);
addOptional(Para,'dig',32);

parse(Para,varargin{:});

nk=Para.Results.nk;
P=Para.Results.P;
Q=Para.Results.Q;
p1=Para.Results.p1;
eta=Para.Results.eta0;
d=Para.Results.d0;
dig=Para.Results.dig;

N = size(nk,1);
data = zeros(N+1,2);
data(1,:)=[eta,d];
for i = 1:N
    n = nk(i,1);
    k = nk(i,2);
    [eta,d] = ESPD('eta',eta, 'd',d,'n',n,'k',k,'P',P,'p1',p1,'Q',Q,'dig',dig);
    data(i+1,:)=[eta,d];
end

end