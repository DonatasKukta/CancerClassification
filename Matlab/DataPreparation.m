%Load data file into wirking directory
clc; clear all;
% Data:
%DataTable = readtable('risk_factors_cervical_cancer.csv');
DataTable = readtable('testData.csv')

QualitiveCols    = {'Smokes' 'HormonalContraceptives' 'IUD' 'STDs' 'STDs_condylomatosis' 'STDs_cervicalCondylomatosis' 'STDs_vaginalCondylomatosis' 'STDs_vulvo_perinealCondylomatosis' 'STDs_syphilis' 'STDs_pelvicInflammatoryDisease' 'STDs_genitalHerpes' 'STDs_molluscumContagiosum' 'STDs_AIDS' 'STDs_HIV' 'STDs_HepatitisB' 'STDs_HPV' 'Dx_Cancer' 'Dx_CIN' 'Dx_HPV' 'Dx'}
QuantitativeCols = {'Age' 'NumberOfSexualPartners' 'FirstSexualIntercourse' 'NumOfPregnancies' 'Smokes_years_' 'Smokes_packs_year_' 'HormonalContraceptives_years_' 'IUD_years_' 'STDs_number_' 'STDs_NumberOfDiagnosis' 'STDs_TimeSinceFirstDiagnosis' 'STDs_TimeSinceLastDiagnosis'}
ResultQualitiveCols = {'Hinselmann' 'Schiller' 'Citology' 'Biopsy'}
%Age,Number of sexual partners,First sexual intercourse,Num of pregnancies,Smokes,Smokes (years),Smokes (packs/year),Hormonal Contraceptives,Hormonal Contraceptives (years),IUD,IUD (years),STDs,STDs (number),STDs:condylomatosis,STDs:cervical condylomatosis,STDs:vaginal condylomatosis,STDs:vulvo-perineal condylomatosis,STDs:syphilis,STDs:pelvic inflammatory disease,STDs:genital herpes,STDs:molluscum contagiosum,STDs:AIDS,STDs:HIV,STDs:Hepatitis B,STDs:HPV,STDs: Number of diagnosis,STDs: Time since first diagnosis,STDs: Time since last diagnosis,Dx:Cancer,Dx:CIN,Dx:HPV,Dx,Hinselmann,Schiller,Citology,Biopsy


missingDataCounts = getMissingValCountByCol(DataTable, size(ResultQualitiveCols,2));
varsToBeRemoved = identifyVariablesToBeDropped(missingDataCounts, height(DataTable), 0.5) ;
[DataTable, QuantitativeCols,QualitiveCols] = removeVariables(DataTable, varsToBeRemoved, QuantitativeCols,QualitiveCols);
%DataTable = removeRows(DataTable(:,DataTable.Properties.VariableNames([QualitiveCols,QuantitativeCols])), 0.5)
DataTable = removeRows(DataTable, 0.5,size(ResultQualitiveCols,2));
temp = processQuantativeCols(DataTable,QuantitativeCols )
% Isvalius ir paruosus duomenis atlikti ekspermentus dimensiju mazinimui:
% Kintamuju tarpusavio priklausomybiu palyginimas;
% ...

%Atlikti normalizacija?
%Jei taip, ar metode esanti normalize() yra gera formule?

% ---------------------Metodai: ---------------------

% Apdoroti kiekybinius stulpelius:
%   suteikti vidutines reiksmes trukstamiem stulpeliams
%   pasalinti nuokrypius
function result = processQuantativeCols(table, quantitativeCols)
    qColCount = size(quantitativeCols,2)
    names = table.Properties.VariableNames
    for i=1:qColCount
       currentName = quantitativeCols(1,i)
       currentNameIndex = find(strcmp(names, currentName))
       currentCol = table{:,currentNameIndex}
       mean = getMean(currentCol)
       sd = getStandartDeviation(currentCol,mean)
       symbol = "?";
       % Cia turime stulpelio standartini nuokrypi ir vidurki. 
       % Klausimai:
       %    Nezinomai reiksmei priskirti vidurki?
       %    Kaip tiksliai nustatyti ar reiksme nukrypusi?
       length = height(table)
       j = 1
       while j <= length
          currentValue = string(currentCol{i,1});
           if isequal( currentValue , symbol)
               %Jei reiksme nezinoma, priskirti vidurki
               currentCol{i,1} = string(mean)
               table{i,currentNameIndex} = cellstr(string(mean))
           else
               % Jei reiksme zinoma, ziureti, ar ji ne per daug nukrypusi
               isDeviated = 1
               if isDeviated
                   %Jei nuokrypis didelis, salinti visa eilute
                   table(j,:) = [];
                   length = length - 1;
                   j = j - 1;
               end
           end
          j = j + 1;
       end
       
    end
    result = 0;
end
% Gauti standartini nuokrypi
function sd =getStandartDeviation(array, mean)
    length = size(array,1);
    numCount = 0;
    sum = 0;
    symbol = "?";    
    for i=1:length
        currentValue = string(array{i,1});
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
        currentValue = string(array{i,1});
        if ~isequal( currentValue , symbol)
            numCount = numCount + 1;
            sum = sum + str2num(currentValue);
        end
    end
    mean = sum / numCount;
end

function result = normalize(x, averageX, maxX, minX)
    result = (x - averageX) / (maxX - minx);
end

% Pasalina eilutes kurios neturi pakankamai daug duomenu
function table = removeRows(table, missingDataThreshold, resultCount)
    table;
    n = height(table);
    rowCount = (width(table) - resultCount);
    i=1;
	while( i <= n)
    row = table(i,:);
    missingCount = getMissingCountinRow(row);
    missingRatio = missingCount / rowCount;
    if missingRatio >= missingDataThreshold
        %pasalinti eilute...
        table(i,:) = [];
        i= i-1;
        n = n-1;
    end
    i = i + 1;
    end  
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
    %      table{eilute, stulpelis};
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