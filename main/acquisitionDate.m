function dAcqDate = acquisitionDate(strDir)
    
% Get date of scene acquisition
strDate = getField(strDir,'.gh','SingleDateTime','CalendarDate');

% Convert to matlab datetime format
dAcqDate = datetime([strDate(5:6) '/' strDate(7:8) '/' strDate(1:4)], ...
    'InputFormat','MM/dd/uuuu');
