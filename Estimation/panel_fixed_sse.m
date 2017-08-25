function [b,R2_adjusted, sse, NumObs] = panel_fixed_sse(Y,X)
%%
M = size(Y,1);
k = size(X,2);
I = ones(M,1);
n_stocks = size(Y,3);
Q = eye(M)-I*I'/M;
%%
XX = NaN(k,k,n_stocks);
XY = NaN(k,1,n_stocks);
for i = 1:n_stocks;
    XX(:,:,i) = X(:,:,i)'*Q*X(:,:,i);
    XY(:,:,i) = X(:,:,i)'*Q*Y(:,:,i);
end;
%%
b = mean(XX,3)\mean(XY,3);
e = NaN(size(Y));
dy = NaN(size(Y));
for i = 1:n_stocks
    e(:,:,i) = Y(:,:,i) - X(:,:,i) * b - mean(Y(:,:,i) - X(:,:,i) * b);
    dy(:,:,i) = Y(:,:,i) - mean(Y(:,:,i));
end;
sse = sum(sum(e.*e));
R2 = 1 - sum(sum(e.*e)) / sum(sum(dy.*dy)) ;

R2_adjusted = 1 - (1-R2)*(M*n_stocks-1)/(n_stocks*(M-1)-k);
NumObs = n_stocks * M;
