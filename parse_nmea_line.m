%parse_nmea_line reads an NMEA sentence into a MATLAB structure array
%
%  data  =  parse_nmea_line(nmealine)
%  [data,errorcode]  =  parse_nmea_line(nmealine)
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
function [data, errorcode] = parse_nmea_line(nmealine)

errorcode  =  0;
%
%%  Set up a list of valid NMEA strings
%
nmea_options  =  { '$GPGGA'
                    '$GPZDA'
                    '$GPVTG'
                    '$PTNL'};
%
%%  Find which string we're dealing with

fields = textscan(nmealine,'%s','delimiter',',');
%pull the checksum out of the last field and make a new one for it
fields{1}{end+1} = fields{1}{end}(end-1:end);
%cut off the old last field at the chksum delimiter
fields{1}(end-1) = strtok(fields{1}(end-1), '*');
case_t = find(strcmp(fields{1}(1), nmea_options),1);
fields = char(fields{1});
%%  If no valid NMEA string found - quit with an error

if isempty(case_t)
    fprintf(1,'\n\tWarning: Not a valid NMEA string  -  %s ...\n',nmealine);
    data  =  NaN;
    errorcode  =  -1;
    return
end
%
%% read and check the checksum
% Initialise checksum 
checksum = uint8(0);      

%calc it - we drop the leading '$' and trim off the '*' and anything past it
for i_char = 2:(find(nmealine=='*',1,'last')-1)
    checksum = bitxor(checksum, uint8(nmealine(i_char))); 
end
checksum = dec2hex(checksum, 2);

%check it
if ((strcmp(fields(end,1:2),checksum))==0)
   %checksum is bad!
    fprintf(1,'\n\tWarning: Checksum Bad  - %s ~= %s',fields(end),checksum);
    data  =  NaN;
    errorcode  =  -1;
    return
end

%% TURN ON THE SWITCH!

switch case_t
    case 1 %% GPGGA Read global positioning system fixed data
        
        %first data field is the time
        t_time  =  fields(2,1:end);
        if(isempty(t_time))
            data.BODCTime  =  NaN;
        else
            data.BODCTime  =  datenum(t_time,'HHMMSS') - ...
                floor(datenum(t_time,'HHMMSS'));
        end
        clear t_time;
        
        %next data field is the lat
        t_lat  =  fields(3,1:end);
        data.latitude  =  ...
            str2double(t_lat(1:2)) + (str2double(t_lat(3:end))/60);
        t_latDir = fields(4,1:end);
        if(t_latDir  ==  'S')
            data.latitude  =  data.latitude  *  -1;
        end
        clear t_lat t_latDir;
        
        %then the lon
        t_lon  = fields(5,1:end);
        data.longitude  =  ...
            str2double(t_lon(1:3)) + (str2double(t_lon(4:end))/60);
        t_lonDir = fields(6,1:end);
        if(t_lonDir  ==  'W')
            data.longitude  =  data.longitude  *  -1;
        end
        clear t_lon t_longDir;
        
        %Get the fix quality where 0 = none, 1 = GPS fix, 2 = DGPS fix
        t_fix = fields(7,1:end);
        data.fix  = str2double(t_fix);
        clear t_fix;
        
        %read the number of satellites
        t_sat = fields(8,1:end);
        data.satellites = str2double(t_sat);
        clear t_sat;
        
        %read HDOP
        t_HDOP= fields(9,1:end);
        if isempty(t_HDOP)
            %do nothing
        else
            data.HDOP = str2double(t_HDOP);
        end
        clear t_HDOP;
        
        %Read Altitude
        t_alt = fields(10,1:end);
        if isempty(t_alt)
            %do nothing
        else
            data.altitude = str2double(t_alt);
        end
        clear t_alt;
        
        t_altUnit = fields(11,1:end);
        if (t_altUnit(1)=='M')
            %do nothing
        else
            fprintf(1,'\tWarning: unknown Altitude Unit - %s\n', t_altUnit);
        end
        clear t_altUnit;
        
        % Height of geoid.... meh
        t_altGeo = fields(12,1:end);
        clear t_altGeo;
        t_altGeoUnit = fields(13,1:end);
        if (t_altGeoUnit(1)=='M')
            %do nothing
        else
            fprintf(1,'\tWarning: unknown Height over WGS84 Unit - %s\n', t_altGeoUnit);
        end
        clear t_altGeoUnit;
        
        %Time since DGPS update
        t_DGPSupdate = fields(14,1:end);
        
        
        %Checksum
        
        t_chkSum = fields(15,1:end);
%     case 2 %%  Read UTC Date / Time and Local Time Zone Offset
%         
%         data.BODCTime  =  (datenum(nmealine(11:20),'dd,mm,yyyy') + ...
%             (datenum(nmealine(1:6),'HHMMSS') - ...
%             floor(datenum(nmealine(1:6),'HHMMSS'))));
%         data.offset  =  (str2double(nmealine(22:23)) + ...
%             (str2double(nmealine(25:26)) / 60)) / 24;
    case 3 %% GPVTG: Read course over ground and ground speed
        
        t_course  =  fields(2,1:end);
        if(isempty(t_course))
            data.truecourse  =  NaN;
        else
            data.truecourse  =  str2double(t_course);
        end
        
        t_course  =  fields(4,1:end);
        if(isempty(t_course))
            data.magneticcourse  =  NaN;
        else
            data.magneticcourse  =  str2double(t_course);
        end
        
        t_gspeed  =  fields(6,1:end);
        if(isempty(t_gspeed))
            data.groundspeed.knot  =  NaN;
        else
            data.groundspeed.knot  =  str2double(t_gspeed);
        end
        
        t_gspeed  =  fields(6,1:end);
        if(isempty(t_gspeed))
            data.groundspeed.kph  =  NaN;
        else
            data.groundspeed.kph  =  str2double(t_gspeed);
        end
        
        clear t_course t_gspeed;
    case 4
        if(sum(fields(2,1:3) == 'PJK') == 3)
            sub_case = 1;
        elseif(sum(fields(2,1:3) == 'AVR') == 3)
            sub_case = 2;
        end
        switch sub_case
            case 1
               	%first data field is the time
                t_time  =  fields(3,1:end);
                if(isempty(t_time))
                    data.BODCTime  =  NaN;
                else
%                     data.BODCTime  =  datenum(t_time,'HHMMSS') - ...
%                         floor(datenum(t_time,'HHMMSS'));
                    data.BODCTime  =  str2date(t_time);
                end
                clear t_time;
                
                t_date = fields(4,1:end);
                data.date = str2double(t_date);
                clear t_date;
                
                t_northing = fields(5,1:end);
                data.northing = str2double(t_northing);
                clear t_northing;
                
                t_easting = fields(7,1:end);
                data.easting = str2double(t_easting);
                clear t_easting;

                %Get the fix quality where 0 = none, 1 = GPS fix, 2 = DGPS fix
                t_fix = fields(9,1:end);
                data.fix  = str2double(t_fix);
                clear t_fix;
                
                %read the number of satellites
                t_sat = fields(10,1:end);
                data.satellites = str2double(t_sat);
                clear t_sat;
        
                %read DOP
                t_DOP= fields(11,1:end);
                if isempty(t_DOP)
                    %do nothing
                else
                data.DOP = str2double(t_DOP);
                end
                clear t_DOP;
        
                %Read Altitude
                t_alt = fields(12,1:end);
                if isempty(t_alt)
                    %do nothing
                else
                    data.altitude = str2double(t_alt(4:end));
                    data.altitude_type = t_alt(1:3);
                end
                clear t_alt;
        
            case 2
                data.yaw = str2double(fields(4,1:end));
                data.tilt = str2double(fields(6,1:end));
                data.roll = str2double(fields(8,1:end));
                data.range = str2double(fields(10,1:end));
                %Get the fix quality where 0 = none, 1 = GPS fix, 2 = DGPS fix
                t_fix = fields(11,1:end);
                data.fix  = str2double(t_fix);
                clear t_fix;
        end
    otherwise
        data  =  NaN;
        errorcode  =  -2;
%         fprintf(1,...
%             '\n\tWarning: NMEA reader not yet implemented for this string  -  %s  ...\n',...
%             nmealine);
end

% %%  Tidy up the output structure
% data  =  orderfields(data);