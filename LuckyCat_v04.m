## =============================================================================
## AUTHOR  : NANOUK
## PROJECT : ADVANCED SUMMONING PLANNER FOR SAINT SEIYA AWAKENING
## CREATED : MAY 2020
## =============================================================================
##                         WHAT IS THIS SCRIPT ABOUT?
##
## This script is about how players could use their advanced gems in SSA:KOTZ
## It provides a GUI to help the use of a core function implementing the simple
## rules of summoning in SSA:KOTZ
## 
## Disclaimer: many scenarios cannot be evaluated properly.
## Going all-in may be trickier to simulate as you can go back and forth between
## every bonus you can get: you may play the lucky cat then use all 
## your gems, get the daily bonus, then play more gems, get banner bonus, play
## more gems and be broke ; this scenario goes behind the scope of this script.
## 
## =============================================================================
##                          HOW TO USE THIS SCRIPT?
##
## 1. INSTALL OCTAVE
## 2. LOCATE THE FOLDER CONTAINING THIS SCRIPT AND SWITCH TO THAT DIRECTORY
## 3. LAUNCH THE SCRIPT BY INVOKING ITS NAME IN THE MAIN COMMAND WINDOW
## 4. FILL THE FORM THEN CLICK ON THE SUBMIT BUTTON
## =============================================================================
## 
## *****************************************************************************
## =============================================================================
## Clear console window (a script cannot start with a function definition)
## =============================================================================
## ***************************************************************************** 

clc;
clear;
close all;

## =============================================================================
##                             Helper functions
## =============================================================================

## -----------------------------------------------------------------------------
## SUMMONING STATUS
## -----------------------------------------------------------------------------
function summonings_status = check_summonings_status(current_gems)
summonings_status = (current_gems>0);
endfunction
## -----------------------------------------------------------------------------
## DAILY SUMMONING BONUS
## -----------------------------------------------------------------------------
function daily_summonings_bonus=add_daily_summonings_bonus(actual_summonings)
daily_summonings_thresholds = [3,10,40];
daily_summonings_thresholds_bonus = [1,2,4];
daily_summonings_bonus = daily_summonings_thresholds_bonus*(actual_summonings>=daily_summonings_thresholds)';
endfunction
## -----------------------------------------------------------------------------
## SUMMONING BONUS (THRESHOLDS)
## -----------------------------------------------------------------------------
function bonus=add_summonings_bonus(actual_summonings,total_summonings)
summonings = [60,	100,	200,	300,	450,	650,	900,	1200,	1500];
summonings_bonus = [5,	5,	10,	10,	15,	15,	20,	30,	30];
bonus = (summonings - total_summonings <= actual_summonings).*(summonings>total_summonings)*summonings_bonus';
endfunction
## -------------------------------------------------------------
## LUCKY CAT BONUS
## -------------------------------------------------------------
function lucky_cat_bonus = add_lucky_cat_bonus (current_gems)
## Data based on public survey on reddit
lucky_cat_threshold = [20,	30,	65,	150,	240,	330,	500,	660];
lucky_cat_avg_reward = [3.86,	5.32,	9.78,	15.73,	19.59,	25.60,	34.34,	59.68];
lucky_cat_bonus = round([(current_gems + [0 cumsum(lucky_cat_avg_reward)(1:end-1)])>lucky_cat_threshold]*lucky_cat_avg_reward');
endfunction
## -------------------------------------------------------------
## SHARDS REWARD
## -------------------------------------------------------------
function average_shards = compute_shards(summonings_number)
shard_probability	= [80.37,	18.48,	1.12,	0.03]*1/100;
shard_bonus = [0,	1,	2,	3];
average_shards = round(shard_bonus*shard_probability'*summonings_number);
endfunction
## -------------------------------------------------------------
## CORE FUNCTION
## -------------------------------------------------------------
function compute_scenario(
  user_summoning,
  starting_gems,
  daily_gems_income,
  is_lucky_cat_running,
  lucky_cat_day  
  )

disp(['---------------- New scenario ----------------']);
disp(['Starting number of gems .....: ' num2str(starting_gems)]);
  
bonus = 0;
total_summoning = 0;
total_summonings = [total_summoning];

summonings = [0];
current_gems = starting_gems;
gems_history = [current_gems];

detailed_gem_history = [
  raw_gems=0;
  daily_bonus_gems=0;
  summon_bonus_gems=0;
  0; ## daily_gems_income
  lucky_cat_bonus_gems=0
  ];

xticklabel_days = ['Init'];

for days = 1:length(user_summoning)
  raw_gems = 0;
  daily_bonus_gems = 0;
  summon_bonus_gems = 0;
  lucky_cat_bonus_gems = 0;

  ## Daily gems income
  current_gems = current_gems + daily_gems_income;
  
  ## Lucky cat income
  if is_lucky_cat_running
    if (days == lucky_cat_day)
      disp(['Gems before Lucky Cat .......: ' num2str(current_gems)]);
      lucky_cat_bonus_gems = add_lucky_cat_bonus(current_gems);
      current_gems = current_gems + lucky_cat_bonus_gems;
      disp(['Gems after Lucky Cat ........: ' num2str(current_gems)]);
      disp(['Net profit ..................: ' num2str(lucky_cat_bonus_gems)]);
    endif
  endif
  
  summonings_status = check_summonings_status(current_gems);
  if !summonings_status
    days = days - 1;
    break
  endif

  actual_summoning = min(user_summoning(days),current_gems);
  current_gems = current_gems - actual_summoning;
  raw_gems = current_gems - lucky_cat_bonus_gems;
  
  ## Daily advanced gems in return
  daily_bonus_gems = add_daily_summonings_bonus(actual_summoning);
  current_gems = current_gems + daily_bonus_gems;

  ## Gems in return based on the number of summonings
  summon_bonus_gems = add_summonings_bonus(actual_summoning,total_summoning);
  current_gems = current_gems + summon_bonus_gems;
    
  ## Save current data in arrays
  summonings = [summonings actual_summoning];
  gems_history = [gems_history current_gems];
  xticklabel_days = [xticklabel_days;strcat('Day_{',num2str(days),'}')];
  
  ## Update counters
  total_summoning  = total_summoning + actual_summoning;
  total_summonings = [total_summonings total_summoning];

  ## Save history
  detailed_gem_history = [
    detailed_gem_history,
    [
      raw_gems;
      daily_bonus_gems;
      summon_bonus_gems;
      daily_gems_income;
      lucky_cat_bonus_gems    
    ]
  ];  
endfor

## -------------------------------------------------------------
## DISPLAY RESULTS
## -------------------------------------------------------------

ScreenSize = get(0).screensize;
Screen.width  = ScreenSize(3);
Screen.height = ScreenSize(4);

results = findobj("tag","results");
if ~length(results)
  results = figure("units","normalized","position", [0.2 0.2 0.6 0.6],"tag","results");
endif
figure(results) ## Raises figure

subplot (2, 3, 3);
bar(summonings.*tril(ones(length(summonings),length(summonings))),"stacked");
set(gca,'xticklabel',xticklabel_days);
yshift = max(2,floor(0.1*total_summonings));
text((1:length(total_summonings))-0.16,total_summonings+yshift,num2str(total_summonings'),'color','black','fontsize', 16);
title('Total number of summonings over time');
current_ylim = ylim();
ylim([current_ylim(1) ceil(current_ylim(2)*1.2)]);

subplot (2, 3, 6);
bar(summonings,"stacked");
set(gca,'xticklabel',xticklabel_days);
yshift = max(2,floor(0.5*summonings));
text((1:length(summonings))-0.16,summonings-yshift,num2str(summonings'),'color','white','fontsize', 14);
title('Number of summonings (summoning scenario)');

subplot (1, 3, [1,2]);
detailed_gem_history = reshape(detailed_gem_history,5,days + 1)'; ## loop break may occur at 'days' value
detailed_gem_history_total = detailed_gem_history * ones(5,1);
bar(detailed_gem_history,"stacked");
set(gca,'xticklabel',xticklabel_days);
yshift = max(2,floor(0.1*detailed_gem_history_total));
text((1:length(detailed_gem_history_total))-0.16,detailed_gem_history_total + yshift, num2str(detailed_gem_history_total),'color','black','fontsize', 16)
title('Detailed gem history');
leg = legend([
  'gems after summoning',
  'daily bonus',
  'summon bonus',
  'daily gems income',
  'lucky cat'
  ],'location','southoutside'
);
set (leg, "fontsize", 16);

disp(['Remaining gems ..............: ' num2str(gems_history(end))]);
disp(['Total number of summonings ..: ' num2str(sum(summonings))]);
disp(['Scenario score ..............: ' num2str(gems_history(end)+sum(summonings))]);
disp(['Shard number estimation .....: ' num2str(compute_shards(sum(summonings)))]);
disp(['--------------- End of scenario --------------']);
  
endfunction

## =============================================================================
## =============================================================================
## =============================================================================
##                                 MAIN SCRIPT
## =============================================================================
## =============================================================================
## =============================================================================


## ================
## HELPER FUNCTIONS
## ================

## -----------------------------------------------------
## Implements autofill function for the user input array
## -----------------------------------------------------

function autofill(src, data)
handle = getappdata(gcf,"handle");

switch(true)
case src==handle.autofill_button_03
  autofill_value = 03;
case src==handle.autofill_button_10
  autofill_value = 10;
case src==handle.autofill_button_40
  autofill_value = 40;
case src==handle.autofill_custom
  autofill_value = str2num(get(handle.autofill_custom,"String"));
otherwise
  error ("invalid value");
endswitch
set(handle.day_field,"String",num2str(autofill_value));
endfunction

## -------------------------------------------------------------
## Get data from GUI before running core process and format data
## -------------------------------------------------------------

function process_scenario() 
handle = getappdata(gcf,"handle");

user_summoning = str2num(cell2mat(get(handle.day_field,"String")));
starting_gems = str2num(get(handle.starting_gems,"String"));
daily_gems_income = str2num(get(handle.daily_gems_income,"String"));
is_lucky_cat = cell2mat(get(handle.is_lucky_cat,"Value"));
is_lucky_cat_running = any(is_lucky_cat);

[duration,status] = str2num(get(handle.custom_duration,"String"));
if ~status
 duration = 7;
endif

lucky_cat_day = find(is_lucky_cat);
if ~nnz(lucky_cat_day)
  lucky_cat_day = 0; # no lucky cat
endif

compute_scenario(
  user_summoning(1:duration),
  starting_gems,
  daily_gems_income,
  is_lucky_cat_running,
  lucky_cat_day  
  );
endfunction

## ---------------------------------------------------------------------
## Enable single selection indicating which day the lucky cat is running
## ---------------------------------------------------------------------

function luckycatcheckbox(src,data)
handle = getappdata(gcf,"handle");
set(handle.is_lucky_cat(handle.is_lucky_cat~=src),"Value",0)
endfunction

## -------------------------------------------------------------
## Manage banner duration
## -------------------------------------------------------------
function duration(src,data)
handle = getappdata(gcf,"handle");
set(handle.one_week_banner,"Value",src==handle.one_week_banner);
set(handle.two_week_banner,"Value",src==handle.two_week_banner);

## Enable/Disable Day array fields
switch(true)
case (src==handle.custom_duration)
   [duration,status] = str2num(get(handle.custom_duration,"String"));
   if ~status
     duration = 14;
   endif
case (src==handle.one_week_banner)
   duration = 7;
otherwise
   duration = 14;
endswitch
  
duration = min(length(handle.day_field),duration);
set(handle.custom_duration,"String",num2str(duration));
set(handle.day_field(1:duration),"enable","on");
set(handle.is_lucky_cat(1:duration),"enable","on");
set(handle.day_field(duration+1:end),"enable","inactive");
set(handle.is_lucky_cat(duration+1:end),"enable","inactive");

endfunction

## ====================
## SETUP DEFAULT VALUES
## ====================

default.starting_gems = 150;
default.daily_gems_income = 3;
default.daily_summonings = 3;

## ===========
## MAIN FIGURE
## ===========

## create figure and panel on it

ScreenSize = get(0).screensize;
Screen.width  = ScreenSize(3);
Screen.height = ScreenSize(4);

gui.width  = min(Screen.width,500);
gui.height = min(Screen.height,540);
gui.xpos   = (Screen.width-gui.width)/2;
gui.ypos   = (Screen.height-gui.height)/2;

main_figure = figure("menubar","none","numbertitle","off","Name","Summoning scenarios","units","pixels","position",[gui.xpos gui.ypos gui.width gui.height],"resize","off");

margin.left   = 10;
margin.bottom = 20;
margin.top    = 20;

label.xpos   = margin.left;
label.width  = 160;
label.height = 20;
field.xpos   = 180;
field.width  = 60;
field.height = 20;

## ====================
## FOOTER SUBMIT BUTTON
## ====================

submit_button.width  = 150;
submit_button.height = 40;
main_button  = uicontrol ("parent", main_figure, "string", "Evaluate scenario","position",[(gui.width-submit_button.width)/2 margin.bottom submit_button.width submit_button.height],"callback",@process_scenario);

## =================
## PLAYER DATA PANEL
## =================

player_data_panel_position = floor([0.03 1 0.94 1].*[gui.width 2*margin.bottom+submit_button.height gui.width gui.height-margin.top-margin.bottom-submit_button.height]);

player_data_panel = uipanel("title", "Setup", "units","pixels","position", player_data_panel_position);

ypos   = margin.bottom ;
yshift = 25;

column.label.width = 60;
column.field.width = 60;
generic_button.width  = 90;
generic_button.height = 30;

column.left.label.xpos   = margin.left;
column.left.label.width  = column.label.width;
column.left.label.height = field.height;
column.left.field.xpos   = column.left.label.xpos + column.left.label.width + margin.left;
column.left.field.width  = column.field.width;
column.left.field.height = field.height;
column.left.check.xpos   = column.left.field.xpos + column.left.field.width + margin.left;
column.left.check.width  = column.field.width;
column.left.check.height = field.height;

column.right.label.xpos   = column.left.field.xpos + column.left.field.width + 3*margin.left;
column.right.label.width  = column.label.width;
column.right.label.height = field.height;
column.right.field.xpos   = column.right.label.xpos + column.right.label.width + margin.left;
column.right.field.width  = column.field.width;
column.right.field.height = field.height;
column.right.check.xpos   = column.right.field.xpos + column.right.field.width + margin.left;
column.right.check.width  = column.field.width;
column.right.check.height = field.height;

max_banner_duration = 14;
for indice=max_banner_duration:-1:ceil((max_banner_duration+1)/2)  
  ypos = ypos + yshift;
  
  handle.day_label(indice -7)    = uicontrol("parent", player_data_panel, "units","pixels", "position", [column.left.label.xpos ypos column.left.label.width column.left.label.height], "style", "text", "string", ["day " num2str(indice -7,"%02d")],"horizontalalignment","right");
  handle.day_field(indice -7 )   = uicontrol("parent", player_data_panel, "units","pixels", "position", [column.left.field.xpos ypos column.left.field.width column.left.field.height], "style", "edit", "string",num2str(default.daily_summonings),"horizontalalignment", "left");
  handle.is_lucky_cat(indice -7) = uicontrol("parent", player_data_panel, "units","pixels", "position", [column.left.check.xpos ypos column.left.check.width column.left.check.height], "style", "checkbox","callback",@luckycatcheckbox);
  
  if(mod(max_banner_duration,2)==1)&&(indice==max_banner_duration)
    continue
  endif

  handle.day_label(indice    ) = uicontrol("parent", player_data_panel, "units","pixels", "position", [column.right.label.xpos ypos column.right.label.width column.right.label.height], "style", "text", "string", ["day " num2str(indice,"%02d")],"horizontalalignment","right");
  handle.day_field(indice    ) = uicontrol("parent", player_data_panel, "units","pixels", "position", [column.right.field.xpos ypos column.right.field.width column.right.field.height], "style", "edit", "string",num2str(default.daily_summonings),"horizontalalignment", "left");
  handle.is_lucky_cat(indice)  = uicontrol("parent", player_data_panel, "units","pixels", "position", [column.right.check.xpos ypos column.right.check.width column.right.check.height], "style", "checkbox","callback",@luckycatcheckbox);
endfor

## ===============================
## ADD LABEL TO LUCKY CAT CHECKBOX
## ===============================

ypos = ypos + yshift;
uicontrol("parent", player_data_panel, "units","pixels", "position", [column.left.check.xpos  ypos column.left.check.width  column.left.check.height ], "style", "text", "string", "LC", "horizontalalignment", "left");
uicontrol("parent", player_data_panel, "units","pixels", "position", [column.right.check.xpos ypos column.right.check.width column.right.check.height], "style", "text", "string", "LC", "horizontalalignment", "left");

## ============
## ADD AUTOFILL
## ============

ypos = ypos + yshift + margin.bottom;
handle.autofill_button_03 = uicontrol("parent", player_data_panel, "units","pixels", "position", [margin.left                        ypos generic_button.width generic_button.height], "string", "Autofill 03","horizontalalignment","right","callback",@autofill);
handle.autofill_button_10 = uicontrol("parent", player_data_panel, "units","pixels", "position", [margin.left+generic_button.width   ypos generic_button.width generic_button.height], "string", "Autofill 10","horizontalalignment","right","callback",@autofill);
handle.autofill_button_40 = uicontrol("parent", player_data_panel, "units","pixels", "position", [margin.left+generic_button.width*2 ypos generic_button.width generic_button.height], "string", "Autofill 40","horizontalalignment","right","callback",@autofill);
handle.autofill_custom    = uicontrol("parent", player_data_panel, "units","pixels", "position", [margin.left+generic_button.width*3 ypos label.width          generic_button.height], "style", "edit", "string","custom autofill value","horizontalalignment", "left","callback",@autofill);

## ==========================
## ADD CUSTOM BANNER DURATION
## ==========================

ypos = ypos + yshift + margin.bottom;
handle.two_week_banner = uicontrol("parent", player_data_panel, "units","pixels", "position", [margin.left ypos label.width label.height], "string", "2 weeks banner", "style", "checkbox","callback",@duration);
ypos = ypos + yshift;
handle.one_week_banner = uicontrol("parent", player_data_panel, "units","pixels", "position", [margin.left     ypos label.width label.height], "string", "1 week banner" , "style", "checkbox","callback",@duration);
handle.custom_duration = uicontrol("parent", player_data_panel, "units","pixels", "position", [margin.left+150 ypos label.width label.height], "style", "edit", "horizontalalignment", "left","string","custom duration","callback",@duration);

## ==============
## ADD USER FIELD
## ==============

ypos = ypos + yshift + margin.bottom;
handle.daily_gems_income_label = uicontrol("parent", player_data_panel, "units","pixels", "position", [label.xpos ypos label.width label.height], "style", "text", "string", "Daily gems income","horizontalalignment","left");
handle.daily_gems_income       = uicontrol("parent", player_data_panel, "units","pixels", "position", [field.xpos ypos field.width field.height], "style", "edit", "horizontalalignment", "left","string",num2str(default.daily_gems_income));

ypos = ypos + yshift;
handle.starting_gems_label     = uicontrol("parent", player_data_panel, "units","pixels", "position", [label.xpos ypos label.width label.height], "style", "text", "string", "Starting number of gems","horizontalalignment","left");
handle.starting_gems           = uicontrol("parent", player_data_panel, "units","pixels", "position", [field.xpos ypos field.width field.height], "style", "edit", "horizontalalignment", "left","string",num2str(default.starting_gems));

## =====================================
## SAVE HANDLE OF OBJECTS IN MAIN FIGURE
## =====================================

setappdata(main_figure,"handle",handle);