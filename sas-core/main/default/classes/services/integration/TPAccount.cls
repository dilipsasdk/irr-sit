public class TPAccount {
  public String euroBonusNumber { get; set; }
  public List<Product> products { get; set; }
  public String status { get; set; }
  public String travelPassAccountNumber { get; set; }

  public class Product {
    public String categoryCode { get; set; }
    public String categoryName { get; set; }
    public String externalName { get; set; }
    public String internalName { get; set; }
    public String typeCode { get; set; }
    public String typeName { get; set; }

    public Product(Dom.XmlNode productNode) {
      for (Dom.XmlNode node : productNode.getChildren()) {
        String nodeName = node.getName();
        switch on nodeName {
          when 'CategoryCode' {
            categoryCode = node.getText();
          }
          when 'CategoryName' {
            categoryName = node.getText();
          }
          when 'ExternalName' {
            externalName = node.getText();
          }
          when 'InternalName' {
            internalName = node.getText();
          }
          when 'TypeCode' {
            typeCode = node.getText();
          }
          when 'TypeName' {
            typeName = node.getText();
          }
        }
      }
    }
  }

  public TPAccount(Dom.XmlNode tpAccountNode) {
    List<TPAccount.Product> tempProducts = new List<TPAccount.Product>();

    for (Dom.XmlNode node : tpAccountNode.getChildren()) {
      String nodeName = node.getName();
      switch on nodeName {
        when 'EuroBonusNumber' {
          euroBonusNumber = node.getText();
        }
        when 'Products' {
          for (Dom.XmlNode product : node.getChildren()) {
            tempProducts.add(new TPAccount.Product(product));
          }
        }
        when 'Status' {
          status = node.getText();
        }
        when 'TravelPassAccountNumber' {
          travelPassAccountNumber = node.getText();
        }
      }
    }

    if (tempProducts != null) {
      products = tempProducts;
    }
  }
}
