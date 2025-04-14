@echo off
REM set -euo pipefail
REM IFS=$'\n\t'
REM set -vx

REM bundle install

set bin_dir=%~dp0
set top_dir=%bin_dir%..
echo %top_dir%
REM dir %top_dir%
set spec_dir=%top_dir%\spec
set test_data_dir=%spec_dir%\test_data
set template_dir=%spec_dir%\template

echo %test_data_dir%
dir %test_data_dir%

set template_file_path= %template_dir%\global_setting.yml
set output_file_path= %test_data_dir%\global_setting.yml

ruby %bin_dir%\setupgs.rb %template_file_path% %output_file_path% %test_data_dir%


