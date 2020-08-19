[struct_6_8_16_gfp] = roiGeneration('6_8_16_mcf7gfp_25slysisHB1_36umheightwafer_12sEP_500_100_500_100_532.tif',50,200);
pause
[struct_6_8_16_gfp]=intProf(struct_6_8_16_gfp,5);
close all;
[struct_6_8_16_gfp]=fitPeaks_beads(struct_6_8_16_gfp,1,3);
[struct_6_8_16_gfp]=goodProfiles_beads(struct_6_8_16_gfp,0,1);
[struct_6_8_16_gfp] = bg_calculation(struct_6_8_16_gfp);
save('struct_6_8_16_gfp.mat','struct_6_8_16_gfp');