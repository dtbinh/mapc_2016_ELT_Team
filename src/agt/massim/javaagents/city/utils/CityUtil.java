package massim.javaagents.city.utils;

import eis.iilang.Action;
import eis.iilang.Identifier;
/**
 * Created by ta10 on 09.04.15.
 */
public class CityUtil {

    //TODO 2015: implement if needed

    static public Action action(String name){
        return new Action(name);
    }

    static public Action action(String name, String param){
        return new Action(name, new Identifier(param));
    }

    static public Action gotoAction(){
        return new Action("goto");
    }
    
    static public Action call_breakdown_serviceAction(){
        return new Action("call_breakdown_service");
    }
}
