@IsTest
private class HttpUtils_Test {
  @IsTest
  static void queryParamShouldAcceptEmptyString() {
    String queryParams = HttpUtils.constructQueryParamString(
      new List<List<String>>()
    );
    System.assertEquals(
      '',
      queryParams,
      'Empty input should return empty string'
    );
  }

  @IsTest
  static void queryParamShouldWorkForSingleParam() {
    List<List<String>> input = new List<List<String>>{
      new List<String>{ 'key', 'value' }
    };
    String queryParams = HttpUtils.constructQueryParamString(input);
    System.assertEquals(
      '?key=value',
      queryParams,
      'Single param should be serialised correctly.'
    );
  }

  @IsTest
  static void queryParamShouldWorkForMultipleParams() {
    List<List<String>> input = new List<List<String>>{
      new List<String>{ 'key1', 'value1' },
      new List<String>{ 'key2', 'value2' }
    };
    String queryParams = HttpUtils.constructQueryParamString(input);
    System.assertEquals(
      '?key1=value1&key2=value2',
      queryParams,
      'Multiple params should be serialised correctly.'
    );
  }

  @IsTest
  static void queryParamShouldWorkForRepeatedParams() {
    List<List<String>> input = new List<List<String>>{
      new List<String>{ 'key1', 'value1' },
      new List<String>{ 'key1', 'value2' }
    };
    String queryParams = HttpUtils.constructQueryParamString(input);
    System.assertEquals(
      '?key1=value1&key1=value2',
      queryParams,
      'Repeated params should be repeated in serialisation.'
    );
  }
}
