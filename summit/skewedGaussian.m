function y = skewedGaussian(x, amplitude, mu_x, sigma, alpha)
    y = amplitude*exp(-((x-mu_x).^2)/(2*sigma .^2)).* normcdf(alpha * (x-mu_x));
end