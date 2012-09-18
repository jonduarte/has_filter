-NOT COMPLETE-
  * Add possibility to chain active record methods
      Ex: Article.filter("title" => "Foo").where(:content => "Barz").first
  * Remove `limit` option from `HasFilter#filter`, now you should
    chain limit method from active record or use named scope.
-NOT COMPLETE-

## 0.1.2
  * Add limit option for filtering, default = 100.
  * Fix empty filtering again - Only return nothing when filtering
    options is empty and filter fields is allowed

## 0.1.1
  * Fix nil filtering
  * Fix boolean filtering


## 0.1.0

* Rails 2.3 compatibility
* `filtering` method become `filter`
*  Fix filtering with invalid params, now filter only model's attribute
*  Fix empty filtering

## 0.0.1

*  Initial release
