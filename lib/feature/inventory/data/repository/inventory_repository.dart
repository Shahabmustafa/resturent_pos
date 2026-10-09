import '../datasource/inventory_datasource.dart';
import '../model/inventory_model.dart';

class InventoryRepository {
  final InventoryRemoteDatasource _ds;
  const InventoryRepository(this._ds);

  // Stock
  Future<List<StockItem>> getStock(String branchId)                          => _ds.fetchStock(branchId);
  Future<StockItem>       addStock(StockItem item)                           => _ds.addStock(item);
  Future<StockItem>       updateStock(StockItem item)                        => _ds.updateStock(item);
  Future<void>            deleteStock(int id, String branchId)               => _ds.deleteStock(id, branchId);
  Future<StockItem>       restock(int id, String branchId, double qty)       => _ds.restockItem(id, branchId, qty);

  // Suppliers
  Future<List<Supplier>>  getSuppliers(String branchId)                      => _ds.fetchSuppliers(branchId);
  Future<Supplier>        addSupplier(Supplier supplier)                     => _ds.addSupplier(supplier);
  Future<void>            deleteSupplier(int id, String branchId)            => _ds.deleteSupplier(id, branchId);

  // Transactions
  Future<List<SupTx>>     getTxs(int supplierId, String branchId)            => _ds.fetchTxs(supplierId, branchId);
  Future<SupTx>           addTx(SupTx tx)                                    => _ds.addTx(tx);
}