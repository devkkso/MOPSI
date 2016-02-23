function [x, p, x_list, p_list, cc_grad_list, cc_func_list, cc_dgrad_list, cc_var_list, alpha_list] = steepest_descent_param_record(f, x00, p0, x_obj, tol, kmax, df, hxx, hpx)
%STEEPEST_DESCENT_PARAM_RECORD inverse method of steepest descent
%   [x, p, x_list, p_list, cc_grad_list, cc_func_list, cc_dgrad_list, cc_var_list, alpha_list]
%   (f, x00, p0, x_obj, tol, kmax, df, hxx, hpx)
%   f : objective function to minimize
%   x0 : initial paramters (arguments for the function)
%   tol : paramter for convergence (condition < tolerance)
%   kmax : maximum iteration time
%   df : cell of derivatives (df/dx1, df/dx2, df/dx3, ...)
%   hxx : hessian, cell of cell
%   hpx : hessian, cell of cell

%%
num = true;
if (nargin == 9)
    num = false;
end

%%
n = length(x_obj);
m = length(p0);
fx0 = @(x) f(x, p0);
x0 = steepest_descent(fx0, x00, tol, kmax); % starting point for the new min problem
xk = x0;
pk = p0;
err = 100;
k = 0;
alpha0 = 100;
alphak = alpha0;
grad_old = zeros(size(pk));
grad = grad_old;
t_x_list = zeros(n, kmax);
t_p_list = zeros(m, kmax);
t_alpha_list = zeros(1, kmax);  % initializing convergence list
t_cc_grad_list = zeros(1, kmax);  % initializing convergence list
t_cc_func_list = zeros(1, kmax);  % initializing convergence list
t_cc_dgrad_list = zeros(1, kmax);  % initializing convergence list
t_cc_var_list = zeros(1, kmax);  % initializing convergence list
%%
while (k < kmax && err > tol)
    xk_old = xk;
    pk_old = pk;
    grad_old = grad;
    if num
        xpk = [xk_old, pk_old];
        fxp = @(x) f(x(1:n), x(n+1:n+m));
        hess = hessian(fxp,xpk);
        Dxx = hess(1:n,1:n);
        Dpx = hess(1:n,n+1:n+m);
        grad_x_p = - Dxx \ Dpx;
    else
        Dxx = hxx(xk_old, pk_old);
        Dpx = hpx(xk_old, pk_old);
        %{
        Dxx = zeros(n, n);
        Dpx = zeros(n, m);
        for i = 1:n
            for j = 1:n
                Dxx(i, j) = hxx{i, j}(xk_old, pk_old);
            end
            for j = 1:m
                Dpx(i, j) = hpx{i, j}(xk_old, pk_old);
            end
        end
        %}
        grad_x_p = - Dxx \ Dpx;
    end
    for i = 1:m
        x = 0;
        for j = 1:n
            x = x + 2 * (xk(j) - x_obj(j)) * grad_x_p(j, i);
        end
        grad(i) = x;
    end
    dir = -grad;

    if num
        f_p = @(p) objective_function(f, p, xk_old, x_obj, tol / 100000, kmax);
    else
        f_p = @(p) objective_function(f, p, xk_old, x_obj, tol / 100000, kmax, df);
    end
    alphak = backtracking_ls(f_p, pk_old, dir', grad', alphak*2, 0.5, 0.1, kmax); % create step 
    disp(alphak);
    %alphak = 0.1;
    pk = pk_old + alphak * dir;
    disp(pk)
    fx = @(x) f(x,pk); % mis  jour energie
    xk = steepest_descent(fx, xk, tol, kmax);
    disp(xk)
    
    % RECORD
    for i = 1:n
        t_x_list(i, k+1) = xk(i);
    end
    for i = 1:m
        t_p_list(i, k+1) = pk(i);
    end
    t_alpha_list(k+1) = alphak; % record step
    t_cc_grad_list(k+1) = cc_grad(grad); % record convergence
    t_cc_func_list(k+1) = cc_func(f_p(pk_old), f_p(pk)); % record convergence
    t_cc_dgrad_list(k+1) = cc_dgrad(grad_old, grad); % record convergence
    t_cc_var_list(k+1) = cc_var(xk_old, xk); % record convergence
        
    % CONVERGENCE
    % err = cc_grad(grad); % condition of gradient
    % err = cc_var(xk_old, xk); % condition of objective function difference
    % err = cc_dgrad(grad_old, grad); % condition of gradient difference
    err = cc_var(pk_old, pk); % condition of parameters difference
    % err = min(cc_func(f(xk_old), f(xk)), min(cc_grad(grad), cc_var(xk_old, xk))); % choose value for convergence
    disp(err)
    
    % COUNTUP
    k = k + 1; % increase count
            
end

%%
x_list = zeros(n, k + 1);  % initializing return x list
p_list = zeros(m, k + 1);  % initializing return x list
alpha_list = zeros(1, k);  % initializing return alpha list
cc_grad_list = zeros(1, k);  % initializing return convergence list
cc_func_list = zeros(1, k);  % initializing return convergence list
cc_dgrad_list = zeros(1, k);  % initializing return convergence list
cc_var_list = zeros(1, k);  % initializing return convergence list
for j = 1:n
    x_list(j, 1) = x0(j);
end
for j = 1:m
    p_list(j, 1) = p0(j);
end
for i = 1:k
    for j = 1:n
        x_list(j, i+1) = t_x_list(j, i);
    end
    for j = 1:m
        p_list(j, i+1) = t_p_list(j, i);
    end
    alpha_list(i) = t_alpha_list(i);
    cc_grad_list(i) = t_cc_grad_list(i);
    cc_func_list(i) = t_cc_func_list(i);
    cc_dgrad_list(i) = t_cc_dgrad_list(i);
    cc_var_list(i) = t_cc_var_list(i);
end
x = xk;
p = pk;

end