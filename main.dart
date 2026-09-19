import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import 'dart:typed_data';

void main() async {
WidgetsFlutterBinding.ensureInitialized();
await Hive.initFlutter();
await Hive.openBox('produtos');
await Hive.openBox('mensagens');
await Hive.openBox('compras');
await Hive.openBox('avaliacoes');
await Hive.openBox('categorias');
runApp(const AkilogApp());
}

class AkilogApp extends StatelessWidget {
const AkilogApp({super.key});

@override
Widget build(BuildContext context) {
return MaterialApp(
title: 'Akilog',
theme: ThemeData(
primarySwatch: Colors.blue,
primaryColor: const Color(0xFF1565C0),
colorScheme: ColorScheme.fromSeed(
seedColor: const Color(0xFF1565C0),
primary: const Color(0xFF1565C0),
secondary: const Color(0xFF64B5F6),
),
appBarTheme: const AppBarTheme(
backgroundColor: Color(0xFF1565C0),
foregroundColor: Colors.white,
elevation: 2,
),
floatingActionButtonTheme: const FloatingActionButtonThemeData(
backgroundColor: Color(0xFF1565C0),
foregroundColor: Colors.white,
),
useMaterial3: true,
),
home: const TelaPrincipal(),
debugShowCheckedModeBanner: false,
);
}
}

// ========== MODELOS ==========
class Produto {
final String id;
final String nome;
final double preco;
final String descricao;
String imagem;
String categoria;
String status; // disponivel, vendido
final String vendedor;

Produto({
required this.id,
required this.nome,
required this.preco,
required this.descricao,
required this.imagem,
required this.categoria,
this.status = 'disponivel',
this.vendedor = 'Você',
});

Map<String, dynamic> toMap() => {
'id': id, 'nome': nome, 'preco': preco, 'descricao': descricao,
'imagem': imagem, 'categoria': categoria, 'status': status, 'vendedor': vendedor,
};
factory Produto.fromMap(Map m) => Produto(
id: m['id'], nome: m['nome'], preco: (m['preco'] as num).toDouble(), descricao: m['descricao'],
imagem: m['imagem'], categoria: m['categoria'] ?? 'Geral',
status: m['status'] ?? 'disponivel', vendedor: m['vendedor'] ?? 'Você',
);
}

class Compra {
final String id;
final String produtoId;
final String produtoNome;
final double valor;
final String codigoRastreio;
String status;
final DateTime data;
final String metodoPagamento;
final String? numeroCartao;
final String? chavePix;

Compra({
required this.id, required this.produtoId, required this.produtoNome,
required this.valor, required this.codigoRastreio, required this.status,
required this.data, required this.metodoPagamento, this.numeroCartao, this.chavePix,
});

Map<String, dynamic> toMap() => {
'id': id, 'produtoId': produtoId, 'produtoNome': produtoNome,
'valor': valor, 'codigoRastreio': codigoRastreio, 'status': status,
'data': data.toIso8601String(), 'metodoPagamento': metodoPagamento,
'numeroCartao': numeroCartao, 'chavePix': chavePix,
};
factory Compra.fromMap(Map m) => Compra(
id: m['id'], produtoId: m['produtoId'], produtoNome: m['produtoNome'],
valor: (m['valor'] as num).toDouble(), codigoRastreio: m['codigoRastreio'], status: m['status'],
data: DateTime.parse(m['data']), metodoPagamento: m['metodoPagamento'],
numeroCartao: m['numeroCartao'], chavePix: m['chavePix'],
);
}

class Mensagem {
final String id; final String remetente; final String destinatario;
final String texto; final DateTime hora;
Map<String, dynamic> toMap() => {
'id': id, 'remetente': remetente, 'destinatario': destinatario,
'texto': texto, 'hora': hora.toIso8601String(),
};
factory Mensagem.fromMap(Map m) => Mensagem(
id: m['id'], remetente: m['remetente'], destinatario: m['destinatario'],
texto: m['texto'], hora: DateTime.parse(m['hora']),
);
Mensagem({required this.id, required this.remetente, required this.destinatario, required this.texto, required this.hora});
}

class Avaliacao {
final String id; final String produtoId; final String autor;
final int nota; final String comentario; final DateTime data;
Map<String, dynamic> toMap() => {
'id': id, 'produtoId': produtoId, 'autor': autor,
'nota': nota, 'comentario': comentario, 'data': data.toIso8601String(),
};
factory Avaliacao.fromMap(Map m) => Avaliacao(
id: m['id'], produtoId: m['produtoId'], autor: m['autor'],
nota: m['nota'], comentario: m['comentario'], data: DateTime.parse(m['data']),
);
Avaliacao({required this.id, required this.produtoId, required this.autor, required this.nota, required this.comentario, required this.data});
}

// ========== TELA PRINCIPAL ==========
class TelaPrincipal extends StatefulWidget {
const TelaPrincipal({super.key});
@override State<TelaPrincipal> createState() => _TelaPrincipalState();
}

class _TelaPrincipalState extends State<TelaPrincipal> {
List<Produto> _produtos = []; List<Produto> _filtrados = [];
final Box _caixa = Hive.box('produtos');
final TextEditingController _pesq = TextEditingController();
int _aba = 0; String? _catSelecionada; double? _precoMax;
final List<String> _categorias = ['Todos', 'Eletrônicos', 'Moda', 'Casa', 'Esportes', 'Livros', 'Outros'];

@override void initState() { super.initState(); _carregar(); _pesq.addListener(_aplicarFiltros); }

void _carregar() {
_produtos = _caixa.values.map((p) => Produto.fromMap(Map.from(p))).toList();
_aplicarFiltros();
}

void _aplicarFiltros() {
final termo = _pesq.text.toLowerCase();
setState(() {
_filtrados = _produtos.where((p) {
bool temTexto = p.nome.toLowerCase().contains(termo) || p.descricao.toLowerCase().contains(termo);
bool temCat = _catSelecionada == null || _catSelecionada == 'Todos' || p.categoria == _catSelecionada;
bool temPreco = _precoMax == null || p.preco <= _precoMax!;
return temTexto && temCat && temPreco;
}).toList();
});
}

void _salvar(Produto p) { _caixa.put(p.id, p.toMap()); _carregar(); }
void _excluir(String id) { _caixa.delete(id); _carregar(); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Produto excluído ✅'))); }

Future<String?> _escolherFoto() async {
  final picker = ImagePicker();

  Future<void> escolher(ImageSource source, BuildContext sheetContext) async {
    final f = await picker.pickImage(source: source, imageQuality: 85);
    if (f != null && mounted) {
      final bytes = await f.readAsBytes();
      Navigator.pop(sheetContext, 'base64:${base64Encode(bytes)}');
    }
  }

  return showModalBottomSheet<String?>(
    context: context,
    builder: (c) => SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: const Icon(Icons.camera_alt, color: Color(0xFF1565C0)),
            title: const Text('Câmera'),
            onTap: () => escolher(ImageSource.camera, c),
          ),
          ListTile(
            leading: const Icon(Icons.photo_library, color: Color(0xFF1565C0)),
            title: const Text('Galeria'),
            onTap: () => escolher(ImageSource.gallery, c),
          ),
        ],
      ),
    ),
  );
}

Widget _foto(String src) {
  if (src.startsWith('base64:')) {
    try {
      return Image.memory(
        base64Decode(src.substring(7)),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image),
      );
    } catch (_) {
      return const Icon(Icons.broken_image);
    }
  }
  return Image.network(
    src,
    fit: BoxFit.cover,
    errorBuilder: (context, error, stackTrace) =>
        const Icon(Icons.broken_image),
  );
}

void _formProd({Produto? p}) {
final nome = TextEditingController(text: p?.nome??'');
final preco = TextEditingController(text: p?.preco.toString().replaceAll('.', ',')??'');
final desc = TextEditingController(text: p?.descricao??'');
final categoriaInicial = p?.categoria;
String cat = _categorias.contains(categoriaInicial) && categoriaInicial != 'Todos'
    ? categoriaInicial!
    : 'Outros';
String img = p?.imagem??'';

showModalBottomSheet(context: context, isScrollControlled: true, shape: const RoundedRectangleBorder(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
builder: (ctx) => StatefulBuilder(builder: (_, setModal) => Padding(
padding: EdgeInsets.only(left: 20, right: 20, top: 25, bottom: MediaQuery.of(ctx).viewInsets.bottom + 25),
child: Column(mainAxisSize: MainAxisSize.min, children: [
Text(p == null ? 'Novo Produto' : 'Editar Produto', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
const SizedBox(height: 15),
InkWell(onTap: () async { final n = await _escolherFoto(); if(n!=null) setModal(()=>img=n); },
child: Container(height: 110, width: double.infinity, decoration: BoxDecoration(border: Border.all(color: Colors.grey.shade300), borderRadius: BorderRadius.circular(8)),
child: img.isEmpty ? const Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.add_photo_alternate, size: 36, color: Colors.grey), Text('Adicionar foto', style: TextStyle(color: Colors.grey))])
: ClipRRect(borderRadius: BorderRadius.circular(8), child: _foto(img)),
),
),
const SizedBox(height: 12),
TextField(controller: nome, decoration: const InputDecoration(labelText: 'Nome', border: OutlineInputBorder())),
const SizedBox(height: 10),
TextField(controller: preco, keyboardType: TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Preço R$', border: OutlineInputBorder())),
const SizedBox(height: 10),
DropdownButtonFormField<String>(value: cat, decoration: const InputDecoration(labelText: 'Categoria', border: OutlineInputBorder()),
items: _categorias.where((c)=>c!='Todos').map((c)=>DropdownMenuItem(value: c, child: Text(c))).toList(),
onChanged: (v)=>setModal(()=>cat=v??'Geral'),
),
const SizedBox(height: 10),
TextField(controller: desc, maxLines: 2, decoration: const InputDecoration(labelText: 'Descrição', border: OutlineInputBorder())),
const SizedBox(height: 18),
SizedBox(width: double.infinity, child: ElevatedButton(style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
onPressed: () { if(nome.text.isEmpty||preco.text.isEmpty) return;
final prod = Produto(id: p?.id??DateTime.now().toString(), nome: nome.text, preco: double.parse(preco.text.replaceAll(',', '.')),
descricao: desc.text, imagem: img.isNotEmpty?img:'https://via.placeholder.com/300?text=Akilog', categoria: cat, status: p?.status??'disponivel');
_salvar(prod); Navigator.pop(ctx);
},
child: Text(p == null ? 'Cadastrar ✅' : 'Salvar ✅', style: const TextStyle(fontSize: 16)),
)),
]),
)),
));
}

void _comprar(Produto p) {
showModalBottomSheet(context: context, isScrollControlled: true,
builder: (ctx) => PagamentoTela(produto: p, onConcluido: (compra) {
p.status = 'vendido'; _salvar(p); Navigator.pop(ctx);
Navigator.push(context, MaterialPageRoute(builder: () => TelaRastreio(compra: compra)));
}),
);
}

@override
void dispose() {
  _pesq.dispose();
  super.dispose();
}

@override Widget build(BuildContext context) {
return Scaffold(
appBar: AppBar(title: const Text('Akilog 🛒', style: TextStyle(fontSize: 20)), centerTitle: true),
body: IndexedStack(index: _aba, children: [
_telaProdutos(), const TelaMensagens(), const TelaCompras(), const TelaPerfil(),
 ]),
floatingActionButton: _aba==0 ? FloatingActionButton.extended(onPressed: ()=>_formProd(), icon: const Icon(Icons.add), label: const Text('Anunciar')) : null,
bottomNavigationBar: BottomNavigationBar(currentIndex: _aba, onTap: (i)=>setState(()=>_aba=i), type: BottomNavigationBarType.fixed,
selectedItemColor: const Color(0xFF1565C0),
items: const [
BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Início'),
BottomNavigationBarItem(icon: Icon(Icons.message), label: 'Mensagens'),
BottomNavigationBarItem(icon: Icon(Icons.local_shipping), label: 'Compras'),
BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Perfil'),
 ],
),
);
}

Widget _telaProdutos() {
return Column(children: [
Padding(padding: const EdgeInsets.all(10), child: Column(children: [
TextField(controller: _pesq, decoration: InputDecoration(hintText: 'Pesquisar...', prefixIcon: const Icon(Icons.search, color: Color(0xFF1565C0)),
border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)), filled: true, fillColor: Colors.blue.shade50)),
const SizedBox(height: 10),
SingleChildScrollView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 4),
child: Row(children: _categorias.map((c)=>Padding(padding: const EdgeInsets.symmetric(horizontal: 4),
child: FilterChip(label: Text(c), selected: _catSelecionada == c,
onSelected: (s)=>setState(()=>_catSelecionada = s ? c : null),
selectedColor: Colors.blue.shade100, checkmarkColor: const Color(0xFF1565C0),
),
)).toList(),
),
const SizedBox(height: 8),
Row(children: [
const Text('Até R$', style: TextStyle(color: Colors.grey)),
const SizedBox(width: 6),
Expanded(child: TextField(keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: 'Preço máximo', isDense: true, contentPadding: EdgeInsets.symmetric(horizontal: 8, vertical: 8)),
onChanged: (v) { _precoMax = v.isEmpty ? null : double.tryParse(v.replaceAll(',', '.')); _aplicarFiltros(); },
)),
 ]),
])),
Expanded(child: _filtrados.isEmpty
? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey), SizedBox(height: 12), Text('Nenhum produto encontrado', style: TextStyle(fontSize: 16, color: Colors.grey))]))
: ListView.builder(padding: const EdgeInsets.all(10), itemCount: _filtrados.length,
itemBuilder: (context, i) { final p = _filtrados[i]; return Card(elevation: 3, margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
child: InkWell(onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: ()=>DetalheProduto(produto: p, aoComprar: _comprar, aoAvaliar: _carregar))),
child: Padding(padding: const EdgeInsets.all(12), child: Row(children: [
ClipRRect(borderRadius: BorderRadius.circular(8), child: SizedBox(width: 90, height: 90, child: _foto(p.imagem))),
const SizedBox(width: 12),
Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Text(p.nome, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
const SizedBox(height: 4),
Text('R$${p.preco.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 17, color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
const SizedBox(height: 4),
Text(p.categoria, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
if(p.status=='vendido') Container(margin: const EdgeInsets.only(top: 4), padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
decoration: BoxDecoration(color: Colors.orange.shade100, borderRadius: BorderRadius.circular(4)),
child: const Text('Vendido', style: TextStyle(color: Colors.orange, fontSize: 12))),
 ])),
PopupMenuButton(onSelected: (op) {
if (op == 'editar') _formProd(p: p);
if(op=='excluir') showDialog(context: context, builder: (c)=>AlertDialog(title: const Text('Excluir?'),
actions: [TextButton(onPressed: ()=>Navigator.pop(c), child: const Text('Cancelar')),
TextButton(onPressed: (){Navigator.pop(c); _excluir(p.id);}, child: const Text('Excluir', style: TextStyle(color: Colors.red))),
 ]));
}, itemBuilder: (context) => [const PopupMenuItem(value: 'editar', child: Row(children: [Icon(Icons.edit, size: 18), SizedBox(width: 8), Text('Editar')])),
const PopupMenuItem(value: 'excluir', child: Row(children: [Icon(Icons.delete, size: 18, color: Colors.red), SizedBox(width: 8), Text('Excluir')])),
]),
]))),
);
}),
),
]);
}
}

// ========== TELA DE PAGAMENTO ==========
class PagamentoTela extends StatefulWidget {
final Produto produto;
final Function(Compra) onConcluido;
const PagamentoTela({super.key, required this.produto, required this.onConcluido});
@override State<PagamentoTela> createState() => _PagamentoTelaState();
}

class _PagamentoTelaState extends State<PagamentoTela> {
String _metodo = 'pix';
final _nomeCartao = TextEditingController();
final _numeroCartao = TextEditingController();
final _validade = TextEditingController();
final _cvv = TextEditingController();
final _chavePix = TextEditingController(text: 'akilog@email.com');

void _confirmar() {
if(_metodo=='cartao' && (_numeroCartao.text.length<16 || _nomeCartao.text.isEmpty)) {
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Preencha os dados do cartão'))); return;
}
if(_metodo=='pix' && _chavePix.text.isEmpty) {
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Informe a chave Pix'))); return;
}

final agora = DateTime.now();
final numeroLimpo = _numeroCartao.text.replaceAll(RegExp(r'\D'), '');
final compra = Compra(
  id: agora.toIso8601String(),
  produtoId: widget.produto.id,
  produtoNome: widget.produto.nome,
  valor: widget.produto.preco,
  codigoRastreio: 'AKL${agora.millisecondsSinceEpoch.toString().substring(5)}',
  status: 'Pedido confirmado',
  data: agora,
  metodoPagamento: _metodo == 'pix' ? 'Pix' : 'Cartão de Crédito',
  numeroCartao: _metodo == 'cartao' && numeroLimpo.length >= 4
      ? '**** **** **** ${numeroLimpo.substring(numeroLimpo.length - 4)}'
      : null,
  chavePix: _metodo == 'pix' ? _chavePix.text.trim() : null,
);
Hive.box('compras').put(compra.id, compra.toMap());
widget.onConcluido(compra);
}

@override
void dispose() {
  _nomeCartao.dispose();
  _numeroCartao.dispose();
  _validade.dispose();
  _cvv.dispose();
  _chavePix.dispose();
  super.dispose();
}

@override Widget build(BuildContext context) {
return Padding(padding: EdgeInsets.only(left: 20, right: 20, top: 25, bottom: MediaQuery.of(context).viewInsets.bottom+25),
child: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
const Text('Pagamento', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
const SizedBox(height: 8),
Text(widget.produto.nome, style: const TextStyle(fontSize: 16)),
Text('Total: R$${widget.produto.preco.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
const SizedBox(height: 20),
const Text('Forma de pagamento', style: TextStyle(fontWeight: FontWeight.bold)),
RadioListTile(value: 'pix', groupValue: _metodo, onChanged: (v)=>setState(()=>_metodo=v.toString()),
title: const Text('Pix 📱'), subtitle: const Text('Pagamento instantâneo'), activeColor: const Color(0xFF1565C0)),
RadioListTile(value: 'cartao', groupValue: _metodo, onChanged: (v)=>setState(()=>_metodo=v.toString()),
title: const Text('Cartão de Crédito 💳'), subtitle: const Text('Comprar agora, pagar depois'), activeColor: const Color(0xFF1565C0)),
const SizedBox(height: 10),
if(_metodo=='pix') TextField(controller: _chavePix, decoration: const InputDecoration(labelText: 'Chave Pix do destinatário', border: OutlineInputBorder())),
if(_metodo=='cartao') ...[
TextField(controller: _nomeCartao, decoration: const InputDecoration(labelText: 'Nome no cartão', border: OutlineInputBorder())), const SizedBox(height: 10),
TextField(controller: _numeroCartao, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'Número do cartão', border: OutlineInputBorder(), hintText: '0000 0000 0000 0000')), const SizedBox(height: 10),
Row(children: [Expanded(child: TextField(controller: _validade, decoration: const InputDecoration(labelText: 'Validade', border: OutlineInputBorder(), hintText: 'MM/AA'))), const SizedBox(width: 10),
Expanded(child: TextField(controller: _cvv, keyboardType: TextInputType.number, decoration: const InputDecoration(labelText: 'CVV', border: OutlineInputBorder(), hintText: '123'))),
 ]),
],
const SizedBox(height: 20),
SizedBox(width: double.infinity, child: ElevatedButton(onPressed: _confirmar, style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
child: const Text('Confirmar Pagamento ✅', style: TextStyle(fontSize: 16)),
)),
])),
);
}
}

// ========== DETALHE PRODUTO + AVALIAÇÕES ==========
class DetalheProduto extends StatefulWidget {
final Produto produto;
final Function(Produto) aoComprar;
final Function() aoAvaliar;
const DetalheProduto({super.key, required this.produto, required this.aoComprar, required this.aoAvaliar});
@override State<DetalheProduto> createState() => _DetalheProdutoState();
}
class _DetalheProdutoState extends State<DetalheProduto> {
final Box _caixaAval = Hive.box('avaliacoes');
final _comentCtrl = TextEditingController();
int _nota = 5;
List<Avaliacao> _avals = [];

@override void initState() { super.initState(); _carregarAvaliacoes(); }
void _carregarAvaliacoes() { setState(() { _avals = _caixaAval.values.map((a)=>Avaliacao.fromMap(Map.from(a))).where((a)=>a.produtoId==widget.produto.id).toList(); }); }
@override
void dispose() {
  _comentCtrl.dispose();
  super.dispose();
}

void _enviarAval() {
if(_comentCtrl.text.trim().isEmpty) return;
final av = Avaliacao(id: DateTime.now().toString(), produtoId: widget.produto.id, autor: 'Você', nota: _nota, comentario: _comentCtrl.text.trim(), data: DateTime.now());
_caixaAval.put(av.id, av.toMap());
_comentCtrl.clear(); _carregarAvaliacoes(); widget.aoAvaliar();
ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Avaliação enviada ⭐')));
}

@override Widget build(BuildContext context) {
return Scaffold(appBar: AppBar(title: Text(widget.produto.nome)),
body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
ClipRRect(borderRadius: BorderRadius.circular(12), child: SizedBox(width: double.infinity, height: 250,
child: widget.produto.imagem.startsWith('base64:') ? Image.memory(base64Decode(widget.produto.imagem.substring(7)), fit: BoxFit.cover)
: Image.network(widget.produto.imagem, fit: BoxFit.cover),
)),
const SizedBox(height: 16),
Text(widget.produto.nome, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
const SizedBox(height: 6),
Text('R$${widget.produto.preco.toStringAsFixed(2).replaceAll('.', ',')}', style: const TextStyle(fontSize: 24, color: Color(0xFF1565C0), fontWeight: FontWeight.bold)),
const SizedBox(height: 6),
Chip(label: Text(widget.produto.categoria), backgroundColor: Colors.blue.shade50),
const SizedBox(height: 12),
const Text('Descrição', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
const SizedBox(height: 4),
Text(widget.produto.descricao, style: TextStyle(fontSize: 15, color: Colors.grey.shade700)),
const SizedBox(height: 20),
if(widget.produto.status=='disponivel') SizedBox(width: double.infinity,
child: ElevatedButton(onPressed: ()=>widget.aoComprar(widget.produto), style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 14)),
child: const Text('Comprar Agora 🛒', style: TextStyle(fontSize: 17)),
),
) else const ListTile(leading: Icon(Icons.sell, color: Colors.orange), title: Text('Produto Vendido', style: TextStyle(color: Colors.orange))),
const SizedBox(height: 24),
const Text('Avaliações ⭐', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
const SizedBox(height: 12),
Row(children: [for(var i=1; i<=5; i++) IconButton(onPressed: ()=>setState(()=>_nota=i), icon: Icon(i<=_nota?Icons.star:Icons.star_border, color: Colors.amber, size: 28))]),
TextField(controller: _comentCtrl, maxLines: 2, decoration: const InputDecoration(labelText: 'Seu comentário...', border: OutlineInputBorder())),
const SizedBox(height: 8),
Align(alignment: Alignment.centerRight, child: ElevatedButton(onPressed: _enviarAval, child: const Text('Enviar Avaliação'))),
const SizedBox(height: 16),
..._avals.isEmpty ? [const Text('Seja o primeiro a avaliar!', style: TextStyle(color: Colors.grey))]
: _avals.map((a)=>Card(margin: const EdgeInsets.only(bottom: 8), child: Padding(padding: const EdgeInsets.all(12), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
Row(children: [Text(a.autor, style: const TextStyle(fontWeight: FontWeight.bold)), const Spacer(),
Row(children: [for(var i=1; i<=5; i++) Icon(Icons.star, size: 14, color: i<=a.nota?Colors.amber:Colors.grey.shade300)]),
]),
const SizedBox(height: 4),
Text(a.comentario),
const SizedBox(height: 2),
Text(DateFormat('dd/MM/yyyy').format(a.data), style: TextStyle(fontSize: 11, color: Colors.grey.shade500)),
])))).toList(),
])),
);
}
}

// ========== TELA DE RASTREIO ==========
class TelaRastreio extends StatelessWidget {
final Compra compra;
const TelaRastreio({super.key, required this.compra});

@override Widget build(BuildContext context) {
return Scaffold(appBar: AppBar(title: const Text('Rastreio da Compra 🚚')),
body: SingleChildScrollView(padding: const EdgeInsets.all(20), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
_cardInfo('Produto', compra.produtoNome),
_cardInfo('Valor', 'R$${compra.valor.toStringAsFixed(2).replaceAll('.', ',')}'),
_cardInfo('Pagamento', compra.metodoPagamento),
if(compra.chavePix!=null) _cardInfo('Chave Pix', compra.chavePix!),
if(compra.numeroCartao!=null) _cardInfo('Cartão', compra.numeroCartao!),
_cardInfo('Código de Rastreio', compra.codigoRastreio, destaque: true),
_cardInfo('Status Atual', compra.status),
_cardInfo('Data', DateFormat('dd/MM/yyyy – HH:mm').format(compra.data)),
const SizedBox(height: 30),
const Text('Histórico de Entrega', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Color(0xFF1565C0))),
const SizedBox(height: 15),
_linhaStatus(Icons.check_circle, 'Pedido Confirmado ✅', true),
_linhaStatus(Icons.payment, 'Pagamento Aprovado ✅', true),
_linhaStatus(Icons.inventory_2, 'Produto Despachado ✅', true),
_linhaStatus(Icons.local_shipping, 'Em Trânsito 🚚', true),
_linhaStatus(Icons.home, 'Entregue 📦', false),
 ])),
);
}

Widget _cardInfo(String rot, String val, {bool destaque=false}) => Container(width: double.infinity, margin: const EdgeInsets.only(bottom: 12), padding: const EdgeInsets.all(16),
decoration: BoxDecoration(color: destaque?Colors.blue.shade50:Colors.grey.shade50, borderRadius: BorderRadius.circular(10), border: destaque?Border.all(color: const Color(0xFF1565C0), width: 2):null),
child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(rot, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)), const SizedBox(height: 4),
Text(val, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: destaque?const Color(0xFF1565C0):null))]));

Widget _linhaStatus(IconData ic, String txt, bool ok) => Padding(padding: const EdgeInsets.symmetric(vertical: 10),
child: Row(children: [Icon(ic, color: ok?const Color(0xFF1565C0):Colors.grey.shade300, size: 28), const SizedBox(width: 12),
Expanded(child: Text(txt, style: TextStyle(fontSize: 15, color: ok?Colors.black87:Colors.grey))),
if(ok) const Icon(Icons.check_circle, color: Colors.green, size: 18),
 ]));
}

// ========== TELA MENSAGENS ==========
class TelaMensagens extends StatefulWidget {
const TelaMensagens({super.key}); @override State<TelaMensagens> createState() => _TelaMensagensState();
}
class _TelaMensagensState extends State<TelaMensagens> {
final Box _caixa = Hive.box('mensagens'); final _ctrl = TextEditingController(); List<Mensagem> _msgs = [];
@override void initState() { super.initState(); _carregar(); }
void _carregar() { setState(() { _msgs = _caixa.values.map((m)=>Mensagem.fromMap(Map.from(m))).toList(); _msgs.sort((a,b)=>b.hora.compareTo(a.hora)); }); }
void _enviar() { if(_ctrl.text.trim().isEmpty) return; final m = Mensagem(id: DateTime.now().toString(), remetente: 'Você', destinatario: 'Vendedor', texto: _ctrl.text.trim(), hora: DateTime.now()); _caixa.put(m.id, m.toMap()); _ctrl.clear(); _carregar(); }
@override
void dispose() {
  _ctrl.dispose();
  super.dispose();
}

@override Widget build(BuildContext context) {
return Scaffold(appBar: AppBar(title: const Text('💬 Mensagens')),
body: Column(children: [Expanded(child: _msgs.isEmpty
? const Center(child: Text('Nenhuma mensagem ainda', style: TextStyle(color: Colors.grey)))
: ListView.builder(reverse: true, padding: const EdgeInsets.all(12), itemCount: _msgs.length,
itemBuilder: (context, i) { final m = _msgs[i]; final ehEu = m.remetente=='Você';
return Align(alignment: ehEu?Alignment.centerRight:Alignment.centerLeft,
child: Container(margin: const EdgeInsets.symmetric(vertical: 4), padding: const EdgeInsets.all(12), constraints: const BoxConstraints(maxWidth: 280),
decoration: BoxDecoration(color: ehEu?const Color(0xFF1565C0):Colors.grey.shade200, borderRadius: BorderRadius.circular(16).copyWith(
bottomLeft: ehEu?const Radius.circular(16):Radius.zero, bottomRight: ehEu?Radius.zero:const Radius.circular(16))),
child: Text(m.texto, style: TextStyle(color: ehEu?Colors.white:Colors.black87))),
);
})),
Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8), decoration: BoxDecoration(color: Colors.white, boxShadow: [BoxShadow(color: Colors.grey.shade200, blurRadius: 4)]),
child: Row(children: [Expanded(child: TextField(controller: _ctrl, decoration: InputDecoration(hintText: 'Digite sua mensagem...', border: OutlineInputBorder(borderRadius: BorderRadius.circular(30)), contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10)), onSubmitted: (_) => _enviar())),
const SizedBox(width: 8), IconButton(onPressed: _enviar, icon: const Icon(Icons.send, color: Color(0xFF1565C0), size: 28)),
 ])),
]));
}
}

// ========== TELA COMPRAS ==========
class TelaCompras extends StatelessWidget {
const TelaCompras({super.key}); @override Widget build(BuildContext context) {
final compras = Hive.box('compras').values.map((c)=>Compra.fromMap(Map.from(c))).toList()..sort((a,b)=>b.data.compareTo(a.data));
return Scaffold(appBar: AppBar(title: const Text('📦 Minhas Compras')),
body: compras.isEmpty
? const Center(child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(Icons.shopping_bag_outlined, size: 60, color: Colors.grey), SizedBox(height: 12), Text('Nenhuma compra realizada', style: TextStyle(fontSize: 16, color: Colors.grey))]))
: ListView.builder(padding: const EdgeInsets.all(12), itemCount: compras.length,
itemBuilder: (context, i) { final c = compras[i]; return Card(margin: const EdgeInsets.only(bottom: 12), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
child: ListTile(title: Text(c.produtoNome, style: const TextStyle(fontWeight: FontWeight.bold)),
subtitle: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('R$${c.valor.toStringAsFixed(2).replaceAll('.', ',')}'), Text('Código: ${c.codigoRastreio}', style: TextStyle(fontSize: 12, color: Colors.blue.shade700))]),
trailing: const Icon(Icons.arrow_forward_ios, size: 16), onTap: ()=>Navigator.push(context, MaterialPageRoute(builder: ()=>TelaRastreio(compra: c))),
));
}),
);
}
}

// ========== TELA PERFIL ==========
class TelaPerfil extends StatelessWidget {
const TelaPerfil({super.key}); @override Widget build(BuildContext context) {
return Scaffold(appBar: AppBar(title: const Text('👤 Perfil')),
body: ListView(padding: const EdgeInsets.all(20), children: [
const SizedBox(height: 20),
const CircleAvatar(radius: 50, backgroundColor: Color(0xFF1565C0), child: Text('A', style: TextStyle(fontSize: 40, color: Colors.white))),
const SizedBox(height: 12),
const Center(child: Text('Akilog', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF1565C0)))),
const Center(child: Text('Compre e venda com confiança 💙', style: TextStyle(color: Colors.grey))),
const SizedBox(height: 30),
_itemPerfil(Icons.info, 'Sobre o App', 'Versão 1.0.0'),
_itemPerfil(Icons.payment, 'Pagamentos', 'Pix e Cartão'),
_itemPerfil(Icons.local_shipping, 'Entregas', 'Rastreio em tempo real'),
_itemPerfil(Icons.star, 'Avaliações', 'Dê sua nota'),
_itemPerfil(Icons.help, 'Ajuda', 'Suporte akilog@email.com'),
const SizedBox(height: 30),
const Card(color: Color(0xFF1565C0), child: Padding(padding: EdgeInsets.all(16), child: Text('💙 Feito com carinho para você! Boas vendas e boas compras!', style: TextStyle(color: Colors.white, fontSize: 15), textAlign: TextAlign.center))),
 ]),
);
}
Widget _itemPerfil(IconData ic, String tit, String sub) => ListTile(leading: Icon(ic, color: const Color(0xFF1565C0)), title: Text(tit), subtitle: Text(sub, style: TextStyle(fontSize: 12, color: Colors.grey.shade600)));
}