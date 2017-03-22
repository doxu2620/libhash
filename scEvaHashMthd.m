close all; clearvars; clc;

% add path for *.m files under ./util
addpath('./util');

% specify the hashing method to be evaluated
kMthdName = 'MCSDH';

%%% PREPARATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% initialize parameters for the specified hashing method
paraStr = eval(sprintf('CfgParaStr_%s();', kMthdName));
paraStr.logFilePath = sprintf('%s/%s_%s_%d.log', paraStr.logDirPath, ...
  paraStr.mthdName, paraStr.dataSetName, paraStr.hashBitCnt);
paraStr.rltFilePath = sprintf('%s/%s_%s_%d.mat', paraStr.rltDirPath, ...
  paraStr.mthdName, paraStr.dataSetName, paraStr.hashBitCnt);

% enable diary output
system(sprintf('rm -rf %s', paraStr.logFilePath));
diary(paraStr.logFilePath);

% load dataset, and apply normalization when required
dtSet = LoadDataSet(paraStr);
if paraStr.enblFeatNorm
  if paraStr.trnWithLrnSet
    normFunc = GnrtNormFunc(dtSet.featMatLrn);
    featMatLrn = normFunc(dtSet.featMatLrn);
  else
    normFunc = GnrtNormFunc(dtSet.featMatDtb);
  end
  dtSet.featMatDtb = normFunc(dtSet.featMatDtb);
  dtSet.featMatQry = normFunc(dtSet.featMatQry);
end

%%% METHOD EVALUATION %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

% obtain label vector (or affinity matrix), and pack into a cell array
extrInfo = cell(2, 1);
if paraStr.trnWithLablVec
  extrInfo{1} = dtSet.lablVecDtb;
end
if paraStr.trnWithAfntMat
  extrInfo{2} = dtSet.afntMatDtb;
end

% train a hashing model
tic;
fprintf('[INFO] training a hashing model\n');
if paraStr.trnWithLrnSet
  model = paraStr.trnFuncHndl(dtSet.featMatLrn, paraStr, extrInfo);
else
  model = paraStr.trnFuncHndl(dtSet.featMatDtb, paraStr, extrInfo);
end
fprintf('[INFO] training a hashing model - DONE (%.4f s)\n', toc);

% calculate binary codes for database and query samples
tic;
fprintf('[INFO] calculating binary codes\n');
codeMatDtb = model.hashFunc(dtSet.featMatDtb);
codeMatQry = model.hashFunc(dtSet.featMatQry);
fprintf('[INFO] calculating binary codes - DONE (%.4f s)\n', toc);

% evaluate binary codes generated by the hashing model
tic;
fprintf('[INFO] evaluating the hashing model\n');
if ~isempty(dtSet.linkMat)
  evaRslt = CalcEvaRslt(codeMatDtb, codeMatQry, paraStr, dtSet.linkMat);
else
  evaRslt = CalcEvaRslt(...
    codeMatDtb, codeMatQry, paraStr, dtSet.lablVecDtb, dtSet.lablVecQry);
end
save(paraStr.rltFilePath, 'evaRslt');
fprintf('[INFO] evaluating the hashing model - DONE (%.4f s)\n', toc);

% disable diary output
diary off;
