% HelloWorldScript.m
% זה קובץ MATLAB שמריץ את קובץ ה-MEX HelloWorldMex

% אם קובץ ה-MEX לא בתיקייה הנוכחית, יש להוסיף path:
% addpath('C:\path\to\your\mex\folder');

% קריאה ל-MEX
HelloWorldMex;

% הודעה נוספת ב-MATLAB (אופציונלי)
disp('ה-MEX רץ בהצלחה!');
