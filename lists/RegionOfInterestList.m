classdef RegionOfInterestList < List
    
    methods (Static)
        function listClass = getListClass()
            listClass = 'RegionOfInterest';
        end
    end    
    
    methods
        function outputXML(this, fileID, indent)
            objects = this.getObjects();
            
            XMLHelper.indent(fileID, indent);
            fprintf(fileID, '<regionOfInterestList>\n');
            
            for i = 1:numel(objects)
                objects.outputXML(fileID, indent+1);
            end
            
            XMLHelper.indent(fileID, indent);
            fprintf(fileID, '</regionOfInterestList>\n');
        end
    end
end