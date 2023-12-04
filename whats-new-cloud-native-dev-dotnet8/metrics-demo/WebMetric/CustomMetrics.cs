using System.Diagnostics.Metrics;

namespace WebMetric
{
    public class CustomMetrics
    {
        private readonly Counter<int> _productSoldCounter;

        public CustomMetrics(IMeterFactory meterFactory)
        {
            var meter = meterFactory.Create("WebMetric.Shop");
            _productSoldCounter = meter.CreateCounter<int>("web.metric.product.sold");
        }

        public void ProductSold(string productName, int quantity)
        {
            _productSoldCounter.Add(quantity, new KeyValuePair<string, object?>("web.metric.product.name", productName));
        }
    }
}

public class Product()
{
    public string ProductName { get; set; }
    public int Quantity { get; set; }
}
