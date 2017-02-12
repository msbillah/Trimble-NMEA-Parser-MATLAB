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
function [t_sec] = str2date(t_time)

t_sec = (str2double(t_time(1:2)))*3600 + (str2double(t_time(3:4)))*60 + (str2double(t_time(5:end)));