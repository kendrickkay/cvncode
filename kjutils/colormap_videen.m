function cmap = colormap_videen(n)
if(~exist('n','var') || isempty(n))
    n=64;
end

prgb=...
   [0         0         0         0
    0.0600    0.7500    0.7500    0.7500
    0.1667    1.0000    1.0000    1.0000
    0.2250    1.0000    0.2200    0.5000
    0.2800    0.8750    0.2800    0.8750
    0.3330    0.0820    0.6800    0.0820
    0.3900         0    1.0000         0
    0.4500         0    1.0000    1.0000
    0.5000         0         0         0
    0.5500    0.4000         0    0.2000
    0.6000    0.2000    0.2000    0.3000
    0.6500    0.3000    0.3000    0.5000
    0.7000    0.5000    0.5000    0.8000
    0.7500         0    1.0000         0
    0.8000    0.0625    0.6900    0.0625
    0.8500    1.0000    1.0000         0
    0.9000    1.0000    0.6000         0
    0.9500    1.0000    0.4000         0
    1.0000    1.0000         0         0];

cmap = GenerateColormap(prgb(:,1),prgb(:,2:4),n);