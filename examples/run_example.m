% Generate the ROIs
horzspacing = 50;
vertspacing = 200;
[test_results] = roiGeneration('test_im.tif',horzspacing, vertspacing);
pause

% Generate intensity profiles for each ROI
backgroundwidth = 5;
[test_results]=intProf(test_results, backgroundwidth);
close all;

% Fit peaks and performa quality control
num_peaks = 1;
snr_threshold = 3;
[test_results]=fitPeaks(test_results, num_peaks, snr_threshold);

r2_threshold = 0;
num_peaks = 1;
[test_results]=goodProfiles(test_results, r2_threshold, num_peaks);
save('test_results.mat','test_results');