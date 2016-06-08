classdef NeuroBits < handle
    % neuronal cells processing app
    
    properties (Hidden)
        ui_hFigure
        widget_FolderBrowser
        widget_ImageBrowser
        widget_DrawNeuroTree
        widget_FindPuncta
    end
    
    properties (Constant, Hidden)
        FONT_SIZE = 10;
        FOREGROUND_COLOR = [0.5, 0.5, 0.5]; % GRAY
        BACKGROUND_COLOR = [1, 1, 1]; % WHITE
        GUI_WINDOW_POSITION = [0, 0.15, 0.15, 0.8];
    end
    
    methods
        % method :: NeuroBits
        %  input :: empty
        % action :: class constructor
        function obj = NeuroBits()
            
            % initialize graphical user interface
            obj.renderUI();
            
            % initialize listeners
            addlistener(obj.widget_FolderBrowser, 'event_fileUpdated', @obj.callbackFcn_fileUpdated);
            
        end
        
        % method :: renderUI
        %  input :: class obj
        % action :: render user interface
        function obj = renderUI(obj)
            
            
            %%% --- Main Figure --- %%%
            obj.ui_hFigure = figure(...
                'Visible', 'on',...
                'Tag', 'hNeuroBits',...
                'Name', 'NeuroBits',...
                'Units', 'normalized',...
                'Position', obj.GUI_WINDOW_POSITION,...
                'NumberTitle', 'off',...
                'MenuBar', 'none',...
                'ToolBar', 'none',...
                'Color', obj.BACKGROUND_COLOR,...
                'CloseRequestFcn', @obj.callbackFcn_closeWindow);
            
            %%% --- Load Images --- %%%
            hPan_FolderBrowser = uipanel(...
                'Parent', obj.ui_hFigure,...
                'Title', 'Folder Browser',...
                'TitlePosition', 'lefttop',...
                'FontSize', obj.FONT_SIZE,...
                'BorderType', 'line',...
                'HighlightColor', obj.FOREGROUND_COLOR,...
                'ForegroundColor', obj.FOREGROUND_COLOR,...
                'BackgroundColor', obj.BACKGROUND_COLOR,...
                'Units', 'normalized',...
                'Position', GridLayout([5, 1], [0.015, 0.015], 1, 1));
            obj.widget_FolderBrowser = WidgetFolderBrowser('Parent',hPan_FolderBrowser,...
                                                   'Extension','*.lsm');
            
            %%% --- Browse Images --- %%%
            hPan_ImageBrowser = uipanel(...
                'Parent', obj.ui_hFigure,...
                'Title', 'Image Browser',...
                'TitlePosition', 'lefttop',...
                'FontSize', obj.FONT_SIZE,...
                'BorderType', 'line',...
                'HighlightColor', obj.FOREGROUND_COLOR,...
                'ForegroundColor', obj.FOREGROUND_COLOR,...
                'BackgroundColor', obj.BACKGROUND_COLOR,...
                'Units', 'normalized',...
                'Position', GridLayout([5, 1], [0.015, 0.015], 2, 1));
            obj.widget_ImageBrowser = WidgetImageBrowser('Parent',hPan_ImageBrowser);
            
            %%% --- DrawTree --- %%%
            hPan_DrawTree = uipanel(...
                'Parent', obj.ui_hFigure,...
                'Title', 'Draw Tree',...
                'TitlePosition', 'lefttop',...
                'FontSize', obj.FONT_SIZE,...
                'BorderType', 'line',...
                'HighlightColor', obj.FOREGROUND_COLOR,...
                'ForegroundColor', obj.FOREGROUND_COLOR,...
                'BackgroundColor', obj.BACKGROUND_COLOR,...
                'Units', 'normalized',...
                'Position', GridLayout([5, 1], [0.015, 0.015], 3, 1));
            obj.widget_DrawNeuroTree = WidgetDrawNeuroTree('Parent', hPan_DrawTree, 'ImageHandle', gcf);
            
            %%% --- Find Puncta --- %%%
            hPan_FindPuncta = uipanel(...
                'Parent', obj.ui_hFigure,...
                'Title', 'Find Puncta',...
                'TitlePosition', 'lefttop',...
                'FontSize', obj.FONT_SIZE,...
                'BorderType', 'line',...
                'HighlightColor', obj.FOREGROUND_COLOR,...
                'ForegroundColor', obj.FOREGROUND_COLOR,...
                'BackgroundColor', obj.BACKGROUND_COLOR,...
                'Units', 'normalized',...
                'Position', GridLayout([5, 1], [0.015, 0.015], 4, 1));
            
            %%% --- Batch Processing --- %%%
            hPan_Batch = uipanel(...
                'Parent', obj.ui_hFigure,...
                'Title', 'Batch Job',...
                'TitlePosition', 'lefttop',...
                'FontSize', obj.FONT_SIZE,...
                'BorderType', 'line',...
                'HighlightColor', obj.FOREGROUND_COLOR,...
                'ForegroundColor', obj.FOREGROUND_COLOR,...
                'BackgroundColor', obj.BACKGROUND_COLOR,...
                'Units', 'normalized',...
                'Position', GridLayout([5, 1], [0.015, 0.015], 5, 1));
            
        end
        
        %%% --- CALLBACKS --- %%%
        
        % Update file index
        function obj = callbackFcn_fileUpdated(obj, ~, ~)
            
            % load method in WidgetImageBrowser to show new image
            fileNameNow = obj.widget_FolderBrowser.fileList{obj.widget_FolderBrowser.fileIndex};
            obj.widget_ImageBrowser.loadImage(fileNameNow);
            
        end
        
        % CloseWindow callback
        function obj = callbackFcn_closeWindow(obj, ~, ~)
            if isa(obj.ui_hFigure, 'matlab.ui.Figure')
                set(obj.ui_hFigure,'Visible','off');
                delete(obj.ui_hFigure);
                delete(obj);
            end
        end
    end
    
end


%%% --- Calculates Grid Layout --- %%%
function [uiGrid] = GridLayout(gridSize, margins, spanH, spanW)
    % function :: GridLayout
    %    input :: gridSize (HxW)
    %    input :: margins (HxW)
    %    input :: spanH
    %    input :: spanW
    %   method :: calculates GridLayout
    
    % calculate grid size
    gridHSize = (1 - margins(1) * (gridSize(1) + 1)) / gridSize(1);
    gridWSize = (1 - margins(2) * (gridSize(2) + 1)) / gridSize(2);

    % calculate box position
    gridHPos = flipud(cumsum([margins(1); repmat(gridHSize + margins(1), gridSize(1) - 1, 1)]));
    gridWPos = cumsum([margins(2); repmat(gridWSize + margins(2), gridSize(2) - 1, 1)]);

    % extract grid
    uiGrid = zeros(1,4);
    uiGrid(1) = gridWPos(spanW(1));
    uiGrid(2) = gridHPos(spanH(end));
    uiGrid(3) = length(spanW) * gridWSize + (length(spanW) - 1) * margins(2);
    uiGrid(4) = length(spanH) * gridHSize + (length(spanH) - 1) * margins(1);
    
end