%DataTable = readtable('testData.csv');NoReduction
DataTable = readtable('NoReduction.csv');
targetCols = {'Hinselmann' 'Schiller' 'Citology' 'Biopsy'};
DataTable = ConvertToNumericValues(DataTable);
sickCount = getSickCount(DataTable(:,targetCols));
toRemove = height(DataTable) - (sickCount * 2);
DataTable = reduceRows(DataTable, targetCols, toRemove);
dataArray = table2array(DataTable);
%ismaisomi duomenys
dataArray = dataArray(randperm(size(dataArray, 1)), :)
names = DataTable.Properties.VariableNames;
DataTable = array2table(dataArray);
DataTable.Properties.VariableNames = names;
DataTable
writetable(DataTable, "ReducedRows.csv");
x=0;
function table = reduceRows(table, targets, toRemove)
    totalPatients = height(table)
    removedCount = 0;
    i = 1;    
    while removedCount <= toRemove
        currRow = table(i,targets);
        %saliname tik nesergancius
        remove = ~isSick(currRow);
        if remove
           table(i,:) = [];
           removedCount = removedCount + 1;
        else
            i = i + 1 ;
        end
    end
end

function count = getSickCount(tableRows)
    count = 0;
    for i=1:height(tableRows)
       if  isSick(tableRows(i, :))
           count = count+1;
       end
    end
end

function res = isSick(tableRow)
    res = tableRow{1,1};
    for i=2:width(tableRow)
        if res <= tableRow{1,i}
            res = tableRow{1,i};
        end
    end
end

function newTable = ConvertToNumericValues(oldTable)
newTable = array2table(zeros(height(oldTable),width(oldTable)));
newTable.Properties.VariableNames = oldTable.Properties.VariableNames;
for i=1:width(oldTable)
    currCol = oldTable{:,i};
    colType = convertCharsToStrings(class(currCol));
    if colType ~= "double"
        %currCol = str2double(string(currCol));
        stringCol = string(currCol);
        currCol = str2double(stringCol);
    end
    newTable{:,i} = currCol;    
end
end