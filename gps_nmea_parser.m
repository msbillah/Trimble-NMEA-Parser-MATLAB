% Author(s):            Mohammad Billah                                                
% Last changed date:    $Date: 2017-12-2 $                                                  
% email:                mbill002@ucr.edu
% Website:              http://www.ece.ucr.edu/~mbillah
% 
% All rights reserved.
%                                                                          
% This program carries no warranty, not even the implied                   
% warranty of merchantability or fitness for a particular purpose.         
% 
% Please email bug reports or suggestions for improvements to:
% mbill002@ucr.edu
%
function [] = gps_nmea_parser()

[fname, pname] = uigetfile('*.txt','Select file containing NMEA strings');
fid = fopen([pname,fname],'r');
count_gga = 0;
count_zda = 0;
count_vtg = 0;
count_pjk = 0;
count_avr = 0;
fprintf('Reading file ... \n');
while(true)
    nmealine = fgetl(fid);
    %length(nmealine)
    if(~length(nmealine))
        continue
    end
    if(nmealine == -1)
        break;
    end
    if(sum(nmealine(2:6) == 'GPGGA') == 5)
        count_gga = count_gga + 1;
    elseif(sum(nmealine(2:6) == 'GPZDA') == 5)
        count_zda = count_zda + 1;
    elseif(sum(nmealine(2:6) == 'GPVTG') == 5)
        count_vtg = count_vtg + 1;
    elseif(sum(nmealine(2:9) == 'PTNL,PJK') == 8)
        count_pjk = count_pjk + 1;
    elseif(sum(nmealine(2:9) == 'PTNL,AVR') == 8)
        count_avr = count_avr + 1;
    end
end
if isequal(count_avr,count_gga,count_pjk,count_vtg,count_zda)
    uiwait(msgbox({['Total ' num2str(89) ' messages found.'] 'Click OK to proceed.'},'Success','modal'));
else
    msgbox('Total number of messages is not consistent','Error','error');
end
frewind(fid);


k = 0;
while(true)
    nmealine = fgetl(fid);
    if(isempty(nmealine))
        continue
    end
    if(nmealine == -1)
        break;
    end
    [data, err] = parse_nmea_line(nmealine);
    if((err == 0) && (sum(nmealine(2:6) == 'GPGGA') == 5))
        k = k+1;
        time_gga(k) = data.BODCTime;
        latitude(k) = data.latitude;
        longitude(k) = data.longitude;
        height_msl(k) = data.altitude;
        fix_gga(k) = data.fix;
    elseif((err == 0) && (sum(nmealine(2:9) == 'PTNL,PJK') == 8))
        time_pjk(k) = data.BODCTime;
        date_pjk(k) = data.date;
        northing(k) = data.northing;
        easting(k) = data.easting;
        height_antenna(k) = data.altitude;
        fix_pjk(k) = data.fix;
        %
    elseif((err == 0) && (sum(nmealine(2:9) == 'PTNL,AVR') == 8))
        yaw(k) = data.yaw;
        tilt(k) = data.tilt;
        roll(k) = data.roll;
        range(k) = data.range;
        fix_avr(k) = data.fix;
    end
    clear data err
end
fclose(fid);
%%
clear h;
save('output.mat');
h=msgbox('Data saved to output.mat.','Success');