classdef Image < Data
    properties (SetAccess = private)
        imageData;
    end
    
    methods
        function obj = Image(imageData)
%             warning('Image:TODO', 'TODO: Check that the data is 2 dimensional');
            
            obj.imageData = imageData;
        end
        
        function width = getWidth(this)
            width = size(this.imageData, 2);
        end
        
        function height = getHeight(this)
            height = size(this.imageData, 1);
        end
        
        function imageData = normalisedTo(this, value)
            imageData = (this.imageData ./ max(this.imageData(:))) * value;
        end
        
        function exportToImage(obj)
            warning('TODO: Add functionality');
        end
        
        function exportToLaTeX(obj)
            warning('TODO: Add functionality');
        end
    end
end