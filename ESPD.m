function [Pkn, Qkn] = ESPD(varargin)

Para=inputParser;
addOptional(Para,'eta',0.59);
addOptional(Para,'d',10^(-2));
addOptional(Para,'Q',0.002);
addOptional(Para,'n',8);
addOptional(Para,'k',4);
addOptional(Para,'P',0.99);
addOptional(Para,'p1',0.99);
addOptional(Para,'dig',32);
parse(Para,varargin{:});

eta=Para.Results.eta;
d=Para.Results.d;
Q=Para.Results.Q;
P=Para.Results.P;
p1=Para.Results.p1;
n=Para.Results.n;
k=Para.Results.k;
dig=Para.Results.dig;

digits(dig);
d=vpa(d);
P=vpa(P);
p1=vpa(p1);
Q=vpa(Q);
eta=vpa(eta);
n=vpa(n);
k=vpa(k);

Ps1=P*(eta+(1-eta)*d)+(1-P)*d;
Qs1=Q*(eta+(1-eta)*d)+(1-Q)*d;
Ps10=eta+(1-eta)*d;
Qs10=d;

if n==0 || k==0
    Qkn=1;
else
    Qkn = vpa(0);
    for j = k:n
        Qkn = Qkn + nchoosek(n,j)*(Qs1^j)*(1-Qs1)^(n-j);
    end
    Qkn=Qkn+Qs10*nchoosek(n,k-1)*(Qs1^(k-1))*(1-Qs1)^(n-k+1);
end

if n==0 || k==0
    Ps1k=1;
else
    Ps1k = vpa(0);
    for j = k:n
        Ps1k = Ps1k + nchoosek(n,j)*(Ps1^j)*(1-Ps1)^(n-j);
    end
    Ps1k=Ps1k+Ps10*nchoosek(n,k-1)*Ps1^(k-1)*(1-Ps1)^(n-k+1);
end

if n==0|| k==0
    Pkn=1;
else
    Pkn = p1^(n)*Ps1k;
    for i = 1:n
            inner_sum = vpa(0);
            for j1 = 0:i
                for j2 = 0:(n-i)
                    if (j1 + j2) >= k
                        term = nchoosek(i, j1)*Ps1^j1*(1-Ps1)^(i-j1)*nchoosek(n-i, j2)*Qs1^j2*(1-Qs1)^(n-i-j2);
                        inner_sum = inner_sum + term;
                    end
                end
            end
            inner_sum=inner_sum*(1-Qs10);
            inner_sum1 = vpa(0);
            for j1 = 0:i
                for j2 = 0:(n-i)
                    if (j1 + j2) >= k-1
                        term = nchoosek(i, j1)*Ps1^j1*(1-Ps1)^(i-j1)*nchoosek(n-i, j2)*Qs1^j2*(1-Qs1)^(n-i-j2);
                        inner_sum1 = inner_sum1 + term;
                    end
                end
            end
            inner_sum1=inner_sum1*Qs10;
            Pkn = Pkn + p1^(i-1)*(1-p1)*(inner_sum+inner_sum1);
    end
end

end