%Load data file into wirking directory
clc; clear all;
% Data:
DataTable = readtable('risk_factors_cervical_cancer.csv');
%DataTable = readtable('testData.csv');

QualitiveCols    = {'Smokes' 'HormonalContraceptives' 'IUD' 'STDs' 'STDs_condylomatosis' 'STDs_cervicalCondylomatosis' 'STDs_vaginalCondylomatosis' 'STDs_vulvo_perinealCondylomatosis' 'STDs_syphilis' 'STDs_pelvicInflammatoryDisease' 'STDs_genitalHerpes' 'STDs_molluscumContagiosum' 'STDs_AIDS' 'STDs_HIV' 'STDs_HepatitisB' 'STDs_HPV' 'Dx_Cancer' 'Dx_CIN' 'Dx_HPV' 'Dx'};
QuantitativeCols = {'Age' 'NumberOfSexualPartners' 'FirstSexualIntercourse' 'NumOfPregnancies' 'Smokes_years_' 'Smokes_packs_year_' 'HormonalContraceptives_years_' 'IUD_years_' 'STDs_number_' 'STDs_NumberOfDiagnosis' 'STDs_TimeSinceFirstDiagnosis' 'STDs_TimeSinceLastDiagnosis'};
ResultQualitiveCols = {'Hinselmann' 'Schiller' 'Citology' 'Biopsy'};

% Pasalinti stulpelius, kurie turi per daug trukstanciu reiksmiu
missingDataCounts = getMissingValCountByCol(DataTable, size(ResultQualitiveCols,2));
varsToBeRemoved = identifyVariablesToBeDropped(missingDataCounts, height(DataTable), 0.5) ;
[DataTable, QuantitativeCols,QualitiveCols] = removeVariables(DataTable, varsToBeRemoved, QuantitativeCols,QualitiveCols);

% Pasalinti eilutes, kurios turi atitinkamai trukstamu reiksmiu
DataTable = removeRows(DataTable, 0.5,size(ResultQualitiveCols,2), QualitiveCols);

% Apdoroti stulpelius, kurie turi kiekybines reiksmes 
%   (pasalinti nuokrypius ir nezinomas reiksmes pakeisti vidurkiu).
DataTable = processQuantativeCols(DataTable,QuantitativeCols,3 );

% Paversti visas reiksmes i skaicius bei juos normalizuoti.
DataTable = convertToNormalizedValues(DataTable,QuantitativeCols);

% Sudaryti kovariaciju matrica
matrixData = table2array(DataTable);
covariationMatrix = array2table(cov(matrixData));
covariationMatrix.Properties.VariableNames = DataTable.Properties.VariableNames;
covariationMatrix = covariationMatrix(:,ResultQualitiveCols)
covariationMatrix = removeDuplicationAndNegatives(covariationMatrix)
[allTargets, allFeatures] = separateTargetFromFeatureAttributes(DataTable , ResultQualitiveCols);
allTargets;
allFeatures;
%maxVals = getMaxValues(covariationMatrix);
baseCoeff = 0.05;
coeffStep = 0.1;

writetable(DataTable(:, [QualitiveCols,QuantitativeCols]),"NoReductionFeatures.csv")
writetable(DataTable(:, ResultQualitiveCols),"Targets.csv")
for i = 1:3
    disp(" iteracijos isrinktos dimensijos:")
    fundamentalFeatures = findFundamentalFeatures(allFeatures.Properties.VariableNames,covariationMatrix,baseCoeff)   
    %filename = string(size(fundamentalFeatures,2))+"procSumazintosDim.csv"
    writetable(DataTable(:, [fundamentalFeatures,ResultQualitiveCols]),i+ "All-" + string(size(fundamentalFeatures,2))+"-reducedDim.csv")
    writetable(DataTable(:, fundamentalFeatures),i+ "Features-" + string(size(fundamentalFeatures,2))+"-reducedDim.csv")
    baseCoeff = baseCoeff + coeffStep;
end

%targetMatrix = table2array(allTargets)
%featuresMatrix = table2array(allFeatures)
%writetable(DataTable, 'AllDimensions.csv');
%plotCol = covariationMatrix{:,32};
%n = size(plotCol,1);
%zeroCol = zeros(1,n);
%histogram(DataTable{:,30});
%testuoti su nftool


function fundamentalFeatures = findFundamentalFeatures(features, covTable, atrrCountThreshold)
    fundamentalFeatures = []    
    colCount = width(covTable);
    rowCount = height(covTable);
    attrCount = int8(rowCount * atrrCountThreshold);
    attrCounts = getArray(colCount, attrCount);
    zerosArr = zeros(1,colCount);
    proceed = 1;
    
    while proceed
       for i=1:colCount
           %Randame maksimalia reiksme ir jos indeksa.
          [maxVal, MaxIndex] = max(covTable{:,i});
          currName = features(1,MaxIndex);          
          % Sekanti karta ieskosime naujo max  
          covTable{MaxIndex, i} = 0; 
          maxcoord = [MaxIndex,i, maxVal]
          %Jei reikia
          if attrCounts(1,i) > 0          
            %sumazinti atitinkama attrCounts reiksme vienetu
            attrCounts(1,i) =  attrCounts(1,i) - 1;
          end           
          if ~isempty(fundamentalFeatures)
            if    ismember(currName, fundamentalFeatures)
                continue 
            end
          end
          % prideti max index kintamojo varda i atsakymu masyva 
          fundamentalFeatures = [fundamentalFeatures, currName];  
       end
       proceed = ~isequal(attrCounts,zerosArr);
    end
end

function maxVals = getMaxValues(table)
    maxVals = array2table(max(table{:,:}));
    maxVals.Properties.VariableNames = table.Properties.VariableNames;
end

function matrix = removeDuplicationAndNegatives(matrix)
w = width(matrix);
h = height(matrix);

    for col=1:(width(matrix)-1)
        matrix{:,col} = abs(matrix{:,col});
        startIndex = h - w + col +1;
       for row = startIndex : h
           matrix{row,col} = 0;
       end
    end
    %remove last column from table
    matrix([h-w+1:h],:) = [];
end

function [targetTable, featureTable] = separateTargetFromFeatureAttributes(table, ResultQualitiveCols)
    
targetTable=table;
featureTable=table;
allnames = table.Properties.VariableNames;
    for i = 1:width(table)
      currColName = allnames(1,i);
      [isTarget, index] = ismember(currColName, ResultQualitiveCols);  
      if isTarget
          featureTable(:,currColName) = [];
      else
          targetTable(:,currColName) = [];
      end
    end
    
end

function newTable = convertToNormalizedValues(oldTable, quanC)
newTable = array2table(zeros(height(oldTable),width(oldTable)));
newTable.Properties.VariableNames = oldTable.Properties.VariableNames;
allnames = newTable.Properties.VariableNames;
for i=1:width(oldTable)
    currCol = oldTable{:,i};
    colType = convertCharsToStrings(class(currCol));
    if colType ~= "double"
        %currCol = str2double(string(currCol));
        stringCol = string(currCol);
        currCol = str2double(stringCol);
        %oldTable{:,i} = currCol
    end
    % Jei tai kiekybinis stulpelis- normalizuojame
    [isQuantative, index] = ismember(allnames(1,i), quanC);

    if(isQuantative && isDiffElements(currCol))
        currCol = normalize(currCol);
    end
    newTable{:,i} = currCol;    
end
end

function result = normalize(array)
    minV = min(array);
    maxV = max(array);
    meanV = mean(array);
    result = (array - minV) / (maxV - minV);
end

function rez = isDiffElements(array)
    n = size(array,1) - 1;
    for i=1:n
        if (array(i) ~= array(i+1))
            rez = 1;
           return;
        end
    end
    rez = 0;
    return
end

function table = processQuantativeCols(table, quantitativeCols,SDCoefficient)
    qColCount = size(quantitativeCols,2);
    names = table.Properties.VariableNames;
    for i=1:qColCount
       currentName = quantitativeCols(1,i);
       currentNameIndex = find(strcmp(names, currentName));
       currentCol = table{:,currentNameIndex};
       mean = getMean(currentCol);
       sd = getStandartDeviation(currentCol,mean);
       symbol = "?";
       % Cia turime stulpelio standartini nuokrypi ir vidurki. 
       % Klausimai:
       %    Nezinomai reiksmei priskirti vidurki?
       %    Kaip tiksliai nustatyti ar reiksme nukrypusi?
       length = height(table);
       j = 1;
       minDev = mean - (SDCoefficient * sd );
       maxDev = mean + (SDCoefficient * sd );       
       while j <= length
          currentValue = string(table{:,currentNameIndex}(j,1));
           if isequal( currentValue , symbol)
               %Jei reiksme nezinoma, priskirti vidurki
               table{j,currentNameIndex} = cellstr(string(mean));
           else
               % Jei reiksme zinoma, ziureti, ar ji ne per daug nukrypusi
               currNumVal = str2double(currentValue);
               if currNumVal < minDev || maxDev < currNumVal
                   %Jei nuokrypis didelis, salinti visa eilute
                   table(j,:) = [];
                   length = length - 1;
                   j = j - 1;
               end
           end
          j = j + 1;
       end
    end
end
% Gauti standartini nuokrypi
function sd =getStandartDeviation(array, mean)
    length = size(array,1);
    numCount = 0;
    sum = 0;
    symbol = "?";    
    for i=1:length
        currentValue = string(array(i,1));
        if ~isequal( currentValue , symbol)
            numCount = numCount + 1;
            sum = sum + (str2num(currentValue) - mean)^2;
        end
    end
    sd = sqrt( sum / numCount );
end

% Randa vidurki ( neskaitant ? simbolio)
function mean =getMean(array)
    length = size(array,1);
    numCount = 0;
    sum = 0;
    symbol = "?";    
    for i=1:length
        currentValue = string(array(i,1));
        if ~isequal( currentValue , symbol)
            numCount = numCount + 1;
            sum = sum + str2num(currentValue);
        end
    end
    mean = sum / numCount;
end

% Pasalina eilutes kurios neturi pakankamai daug duomenu
function table = removeRows(table, missingDataThreshold, resultCount, qualCols)
    n = height(table);
    rowCount = (width(table) - resultCount);
    i=1;
	while( i <= n)
    row = table(i,:);
    missingCount = getMissingCountinRow(row);
    missingRatio = missingCount / rowCount;
    hasMissingQualVal = hasMissingValue(row, qualCols);
    if missingRatio >= missingDataThreshold || hasMissingQualVal
        %pasalinti eilute...
        table(i,:) = [];
        i= i-1;
        n = n-1;
    end
    i = i + 1;
    end  
end

function rez = hasMissingValue(tableRow, Cols)
    colN = width(tableRow);
    allNames = tableRow.Properties.VariableNames;
    symbol = "?";
    for col = 1:colN
        [isInCols, index] = ismember(allNames(1,col), Cols);
        %Jei stulpelis yra tarp nurodyru stulpeliu
        if isInCols
            val = string(tableRow{1,col}(1,1));
            %Jei kintamojo reiksme yra nezinoma
            if isequal( val,symbol)
                % return true
                rez = 1;
                return;
            else
            end
        end
    end
    %return false
    rez = 0;
    return;
end

function count = getMissingCountinRow(row)
    n = width(row);
    count = 0;
    symbol = "?";
    for i=1:n
        val = string(row{1,i}(1,1));
       if isequal(val ,symbol)
           count = count + 1;
       end
    end
end

function [newTable, quanC, qualC] = removeVariables(table, vars, quanC, qualC)
    N = size(vars,1);
    names = table.Properties.VariableNames;
    newTable = table;
    for i = 1:N
        name = {char(names(1,vars(i,1)))};
        newTable = removevars(newTable,name(1));
        quanC = setdiff(quanC, name);
        qualC = setdiff(qualC, name);
    end
end


function result = identifyVariablesToBeDropped(errorCounts, dataRows,missingThreshold)
    N = size(errorCounts, 2);
    result = [];
    for i=1:N
        missRatio = errorCounts(1,i) / dataRows;
        if missRatio > missingThreshold
            result = [result; i];
        end
    end
end

function errorDataCount = getMissingValCountByCol(table, resultCount)
    colN = width(table) - resultCount;
    rowN = height(table);
    errorDataCount = zeros(1,colN);
    symbol = "?";
    for col = 1:colN
        for row = 1 : rowN
            val = string(table{row,col}(1,1));
            if isequal( val,symbol)
                cnt = errorDataCount(1, col);
                errorDataCount(1, col) = cnt+ 1;
            else
            end
        end
    end
end

function array = getArray(length, value)
    array = zeros(1,length)
    for i=1:length
        array(1,i) = value;
    end
end