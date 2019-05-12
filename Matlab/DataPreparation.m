%Load data file into wirking directory
clc; clear all;
% Data:
DataTable = readtable('risk_factors_cervical_cancer.csv');
%DataTable = readtable('testData.csv');

%QualitiveCols    = {'Smokes' 'HormonalContraceptives' 'IUD' 'STDs' 'STDs_condylomatosis' 'STDs_cervicalCondylomatosis' 'STDs_vaginalCondylomatosis' 'STDs_vulvo_perinealCondylomatosis' 'STDs_syphilis' 'STDs_pelvicInflammatoryDisease' 'STDs_genitalHerpes' 'STDs_molluscumContagiosum' 'STDs_AIDS' 'STDs_HIV' 'STDs_HepatitisB' 'STDs_HPV' 'Dx_Cancer' 'Dx_CIN' 'Dx_HPV' 'Dx'}
%QuantitativeCols = {'Age' 'NumberOfSexualPartners' 'FirstSexualIntercourse' 'NumOfPregnancies' 'Smokes_years_' 'Smokes_packs_year_' 'HormonalContraceptives_years_' 'IUD_years_' 'STDs_number_' 'STDs_NumberOfDiagnosis' 'STDs_TimeSinceFirstDiagnosis' 'STDs_TimeSinceLastDiagnosis'}
ResultQualitiveCols = {'Hinselmann' 'Schiller' 'Citology' 'Biopsy'}
%Age,Number of sexual partners,First sexual intercourse,Num of pregnancies,Smokes,Smokes (years),Smokes (packs/year),Hormonal Contraceptives,Hormonal Contraceptives (years),IUD,IUD (years),STDs,STDs (number),STDs:condylomatosis,STDs:cervical condylomatosis,STDs:vaginal condylomatosis,STDs:vulvo-perineal condylomatosis,STDs:syphilis,STDs:pelvic inflammatory disease,STDs:genital herpes,STDs:molluscum contagiosum,STDs:AIDS,STDs:HIV,STDs:Hepatitis B,STDs:HPV,STDs: Number of diagnosis,STDs: Time since first diagnosis,STDs: Time since last diagnosis,Dx:Cancer,Dx:CIN,Dx:HPV,Dx,Hinselmann,Schiller,Citology,Biopsy


missingDataCounts = getMissingValCountByCol(DataTable, size(ResultQualitiveCols,2))
varsToBeRemoved = identifyVariablesToBeDropped(missingDataCounts, height(DataTable), 0.5) 
DataTable = removeVariables(DataTable, varsToBeRemoved)
%summary(Data);

function newTable = removeVariables(table, vars)
    N = size(vars,1)
    names = table.Properties.VariableNames;
    newTable = table;
    for i = 1:N
        name = char(names(1,vars(i,1)))
        name = {name}
        newTable = removevars(newTable,name(1));
    end

end


function result = identifyVariablesToBeDropped(errorCounts, dataRows,missingThreshold)
    N = size(errorCounts, 2)
    result = []
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