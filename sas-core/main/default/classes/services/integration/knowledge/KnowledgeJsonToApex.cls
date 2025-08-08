global class KnowledgeJsonToApex {
  global List<Item> items;

  global class Item {  
    global Sys sys;
    global Fields fields;
  }
    
  global class Sys {
    global String id;	    
    global String type;	  
    global String linkType;	   
    global Integer revision;	   
    global String locale;
    global DateTime createdAt;
    global DateTime updatedAt;
    global AdditionalDetail createdBy;
    global AdditionalDetail updatedBy;
    global AdditionalDetail space;
    global AdditionalDetail environment;
    global AdditionalDetail contentType;
  }

  global class AdditionalDetail {
    global Sys sys;
  }
  
  global class Fields {
    global String id;
    global String title;
    global String body;
    global String description;
    global String target;
    global String itemType;
    global String type;
    global String subType;
    global String url;
    global Boolean confidential;
    global Boolean searchable;
    global File file;
  }

  global class File {
    global String url;
    global Details details;
    global String fileName;
    global String contentType;	 
  }

  global class Entry {
    global Sys sys;
    global Fields fields;
  }

  global class Asset {
    global Sys sys;
    global Metadata metadata;
    global Fields fields;
  }

  global class Metadata {
    global List<Sys> tags;
  }

  global class Details {
    global Integer size;	 
  }	

  public static KnowledgeJsonToApex parse(String json) {
    return (KnowledgeJsonToApex) System.JSON.deserialize(
      json,
      KnowledgeJsonToApex.class
    );
  }
}