classdef WidgetImageBrowser < handle
    
    properties
        image
        width
        height
        stacks
        channels
        bits
        xResolution
        yResolution
        channelIndex
        stackIndex
        fileName
    end
    
    properties %(Access=protected)
        ui_imageFigure
        ui_imageAxis
        ui_imageHandle
        ui_parent
        ui_panel
        ui_pushButton_prevChannel
        ui_pushButton_nextChannel
        ui_pushButton_prevStack
        ui_pushButton_nextStack
        ui_text_imageResolution
        ui_text_channelCounter
        ui_text_stackCounter
        ui_pushButton_applyProjection
        ui_popup_chooseProjection
    end
    
    methods
        function obj = WidgetImageBrowser(varargin)
            
            p = inputParser;
            addParameter(p, 'Parent', [], @isgraphics);
            addParameter(p, 'FileName', [], @ischar);
            addParameter(p, 'Axes', [], @isgraphics);
            parse(p, varargin{:});
            
            if isempty(p.Results.Parent)
                obj.ui_parent = figure;
            else
                obj.ui_parent = p.Results.Parent;
            end
            obj.fileName = p.Results.FileName;
            
            
            % set defaults
            obj.channelIndex = 1;
            obj.stackIndex = 1;
            
            % render user interface
            obj.renderUI();
            
            % if file is provided
            if ~isempty(obj.fileName)
                obj.loadImage();
            end
            
        end
        
        function obj = renderUI(obj)
            
            obj.ui_panel = uipanel(...
                'Parent', obj.ui_parent,...
                'BorderType', 'none',...
                'BackgroundColor', obj.BackgroundColor,...
                'Unit', 'normalized',...
                'Position', [0,0,1,1]);
            
            obj.ui_text_channelCounter = uicontrol(...
                'Parent', obj.ui_panel,...
                'Style', 'text',...
                'String', 'channel 0 / 0',...
                'BackgroundColor', obj.BackgroundColor,...
                'Units', 'normalized',...
                'Position', GridLayout([4,4],[0.01,0.01],1,1:2));
            
            obj.ui_pushButton_prevChannel = uicontrol(...
                'Parent', obj.ui_panel,...
                'Style', 'PushButton',...
                'String', '<<',...
                'Enable', 'off',...
                'Callback', @obj.callbackFcn_prevChannel,...
                'Units', 'normalized',...
                'Position', GridLayout([4,4],[0.01,0.01],1,3));
            
            obj.ui_pushButton_nextChannel = uicontrol(...
                'Parent', obj.ui_panel,...
                'Style', 'PushButton',...
                'String', '>>',...
                'Enable', 'off',...
                'Callback', @obj.callbackFcn_nextChannel,...
                'Units', 'normalized',...
                'Position', GridLayout([4,4],[0.01,0.01],1,4));
            
            obj.ui_text_stackCounter = uicontrol(...
                'Parent', obj.ui_panel,...
                'Style', 'text',...
                'String', 'stack 0 / 0',...
                'BackgroundColor', obj.BackgroundColor,...
                'Units', 'normalized',...
                'Position', GridLayout([4,4],[0.01,0.01],2,1:2));
            
            obj.ui_pushButton_prevStack = uicontrol(...
                'Parent', obj.ui_panel,...
                'Style', 'PushButton',...
                'String', '<<',...
                'Enable', 'off',...
                'Callback', @obj.callbackFcn_prevStack,...
                'Units', 'normalized',...
                'Position', GridLayout([4,4],[0.01,0.01],2,3));
            
            obj.ui_pushButton_nextStack = uicontrol(...
                'Parent', obj.ui_panel,...
                'Style', 'PushButton',...
                'String', '>>',...
                'Enable', 'off',...
                'Callback', @obj.callbackFcn_nextStack,...
                'Units', 'normalized',...
                'Position', GridLayout([4,4],[0.01,0.01],2,4));
            
            obj.ui_text_imageResolution = uicontrol(...
                'Parent', obj.ui_panel,...
                'Style', 'text',...
                'String', 'load image',...
                'BackgroundColor', obj.BackgroundColor,...
                'Units', 'normalized',...
                'Position', GridLayout([4,4],[0.01,0.01],3,1:4));
            
            obj.ui_pushButton_applyProjection = uicontrol(...
                'Parent', obj.ui_panel,...
                'Style', 'PushButton',...
                'String', 'Projection',...
                'Enable', 'off',...
                'Callback', @obj.callbackFcn_applyProjection,...
                'Callback', [],...
                'Units', 'normalized',...
                'Position', GridLayout([4,4],[0.01,0.01],4,1:2));
            
            obj.ui_popup_chooseProjection = uicontrol(...
                'Parent', obj.ui_panel,...
                'Style', 'PopUp',...
                'String', {'Max';'Sum';'Std'},...
                'BackgroundColor', obj.BackgroundColor,...
                'Units', 'normalized',...
                'Position', GridLayout([4,4],[0.01,0.01],4,3:4));
            
        end
        
        function value = BackgroundColor(obj)
            if isa(obj.ui_parent, 'matlab.ui.Figure')
                value = get(obj.ui_parent, 'Color');
            elseif isa(obj.ui_parent, 'matlab.ui.container.Panel')
                value = get(obj.ui_parent, 'BackgroundColor');
            end
        end
        
        function obj = loadImage(obj, fileName)
            obj.fileName = fileName;
            
            % close previous image
            if ~isempty(obj.ui_imageFigure) && isgraphics(obj.ui_imageFigure)
                close(obj.ui_imageFigure);
            end
            
            obj.updateImage();
        end
        
        function obj = updateImage(obj)
            
            % read image
            obj.readImage();
                                  
            % update user interface
            obj.updateUI();
            
            % show image
            obj.showImage();
            
        end
        
        function obj = readImage(obj)
            % read Image
            stack = tiffread(obj.fileName, obj.stackIndex,...
                             'ReadUnknownTags', true,...
                             'DistributeMetaData', true);
            
            % update metadata
            obj.width = stack.width;
            obj.height = stack.height;
            obj.stacks = stack.lsm.DimensionZ;
            obj.channels = stack.lsm.DimensionChannels;
            obj.xResolution = stack.lsm.VoxelSizeX * 1e6;
            obj.yResolution = stack.lsm.VoxelSizeY * 1e6;
            obj.bits = stack.bits;
            obj.image = stack.data{obj.channelIndex};
        end
        
        function obj = updateUI(obj)
            
            % update meta data message
            set(obj.ui_text_imageResolution,...
                'String',sprintf('%d bits, H x W %d x %d\n(%.2f x %.2f um)',...
                obj.bits, obj.height, obj.width,...
                obj.height * obj.yResolution,...
                obj.width * obj.xResolution));
            
            set(obj.ui_text_channelCounter,...
                'String',sprintf('channel %d / %d',...
                obj.channelIndex, obj.channels));
            
            set(obj.ui_text_stackCounter,...
                'String',sprintf('stack %d / %d',...
                obj.stackIndex, obj.stacks));
            
            % update stack buttons callbacks
            if obj.stacks == 1
                set(obj.ui_pushButton_prevStack,'Enable','off');
                set(obj.ui_pushButton_nextStack,'Enable','off');
                set(obj.ui_pushButton_applyProjection,'Enable','off');
            else
                set(obj.ui_pushButton_prevStack,'Enable','on');
                set(obj.ui_pushButton_nextStack,'Enable','on');
                set(obj.ui_pushButton_applyProjection,'Enable','on');
            end
            
            % update channel buttons callbacks
            if obj.channels == 1
                set(obj.ui_pushButton_prevChannel,'Enable','off');
                set(obj.ui_pushButton_nextChannel,'Enable','off');
            else
                set(obj.ui_pushButton_prevChannel,'Enable','on');
                set(obj.ui_pushButton_nextChannel,'Enable','on');
            end
            
        end
        
        function obj = showImage(obj)
            % create new axes
            if isempty(obj.ui_imageAxis) || ~isgraphics(obj.ui_imageAxis)
                
                % calculate figure resize ratio
                sizeImage = [obj.height, obj.width];
                sizeScrn = get(0, 'ScreenSize');
                ratioResize = floor(100*0.8*min(sizeScrn(3:4))/max(sizeImage(1:2)))/100;
                if ratioResize > 1
                    ratioResize = 1;
                end
                
                % calculate figure positions
                figW = ceil(sizeImage(2) * ratioResize);
                figH = ceil(sizeImage(1) * ratioResize);
                figX = round(0.5*(sizeScrn(3) - figW));
                figY = sizeScrn(4) - figH;
                
                obj.ui_imageFigure = figure(...
                       'Color','w',...
                       'Visible','on',...
                       'MenuBar','none',...
                       'ToolBar','none',...
                       'Name','',...
                       'NumberTitle','off',...
                       'Units','pixels',...
                       'Position', [figX, figY, figW, figH]);
                obj.ui_imageAxis = axes(...
                    'Parent', obj.ui_imageFigure,...
                    'Units','normalized',...
                    'XTick',[],...
                    'YTick',[],...
                    'Position',[0,0,1,1]);
                
                obj.ui_imageHandle = imshow(...
                    obj.image,[],...
                    'Parent', obj.ui_imageAxis,...
                    'Border','tight',...
                    'InitialMagnification','fit');
                
            else % update CData of old image
                set(obj.ui_imageHandle,'CData', obj.image);
            end
        end
        
        %%% --- Callback functions --- %%%
        function obj = callbackFcn_prevChannel(obj, ~, ~)
            obj.channelIndex = obj.channelIndex - 1;
            if (obj.channelIndex < 1)
                obj.channelIndex = obj.channels;
            end
            obj.updateImage();
        end
        
        function obj = callbackFcn_nextChannel(obj, ~, ~)
            obj.channelIndex = obj.channelIndex + 1;
            if (obj.channelIndex > obj.channels)
                obj.channelIndex = 1;
            end
            obj.updateImage();
        end
        
        function obj = callbackFcn_prevStack(obj, ~, ~)
            obj.stackIndex = obj.stackIndex - 1;
            if (obj.stackIndex < 1)
                obj.stackIndex = obj.stacks;
            end
            obj.updateImage();
        end
        
        function obj = callbackFcn_nextStack(obj, ~, ~)
            obj.stackIndex = obj.stackIndex + 1;
            if (obj.stackIndex > obj.stacks)
                obj.stackIndex = 1;
            end
            obj.updateImage();
        end
        
        function obj = callbackFcn_applyProjection(obj, ~, ~)
            
            % read full stack
            stack = tiffread(obj.fileName, [],...
                             'ReadUnknownTags', true,...
                             'DistributeMetaData', true);
                         
            imgfull = zeros(             
            
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
