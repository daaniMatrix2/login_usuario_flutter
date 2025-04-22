from fastapi import FastAPI, HTTPException
from pydantic import BaseModel
from typing import List, Optional
from datetime import date
from sqlalchemy import create_engine, Column, Integer, String, Float, Date, ForeignKey
from sqlalchemy.orm import declarative_base, sessionmaker, relationship
from passlib.context import CryptContext

pwd_context = CryptContext(schemes=["bcrypt"], deprecated="auto")


# Configuração do banco de dados SQLite
DATABASE_URL = "sqlite:///./gastos.db"
engine = create_engine(DATABASE_URL, connect_args={"check_same_thread": False})
SessionLocal = sessionmaker(bind=engine)
Base = declarative_base()

class Usuario(Base):
    __tablename__ = "usuarios"
    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String)
    email = Column(String, unique=True, index=True)
    senha_hash = Column(String)
    gastos = relationship("Gasto", back_populates="usuario")

    def verificar_senha(self, senha: str) -> bool:
        return pwd_context.verify(senha, self.senha_hash)

class Gasto(Base):
    __tablename__ = "gastos"
    id = Column(Integer, primary_key=True, index=True)
    valor = Column(Float)
    descricao = Column(String)
    data = Column(Date)
    categoria_id = Column(Integer, ForeignKey("categorias.id"))
    usuario_id = Column(Integer, ForeignKey("usuarios.id"))   # NOVO
    categoria = relationship("Categoria", back_populates="gastos")
    usuario = relationship("Usuario", back_populates="gastos")

# Modelos SQLAlchemy
class Categoria(Base):
    __tablename__ = "categorias"
    id = Column(Integer, primary_key=True, index=True)
    nome = Column(String, unique=True, index=True)
    gastos = relationship("Gasto", back_populates="categoria")

class GastoCreate(BaseModel):
    valor: float
    descricao: str
    data: date
    categoria_id: int
    usuario_id: int  # NOVO



# Criando as tabelas
Base.metadata.create_all(bind=engine)

# Modelos Pydantic
class CategoriaCreate(BaseModel):
    nome: str

class CategoriaOut(BaseModel):
    id: int
    nome: str
    class Config:
        orm_mode = True

class UsuarioCreate(BaseModel):
    nome: str
    email: str
    senha: str

class UsuarioOut(BaseModel):
    id: int
    nome: str
    email: str
    class Config:
        orm_mode = True

class LoginRequest(BaseModel):
    email: str
    senha: str

class GastoOut(BaseModel):
    id: int
    valor: float
    descricao: str
    data: date
    categoria: CategoriaOut
    class Config:
        orm_mode = True

# Inicialização do FastAPI
app = FastAPI()

# Dependência de sessão do banco de dados
def get_db():
    db = SessionLocal()
    try:
        yield db
    finally:
        db.close()

# Rotas de categorias
@app.post("/categorias", response_model=CategoriaOut)
def criar_categoria(categoria: CategoriaCreate):
    db = next(get_db())
    db_categoria = Categoria(nome=categoria.nome)
    db.add(db_categoria)
    db.commit()
    db.refresh(db_categoria)
    return db_categoria

@app.get("/categorias", response_model=List[CategoriaOut])
def listar_categorias():
    db = next(get_db())
    return db.query(Categoria).all()

@app.delete("/categorias/{categoria_id}")
def deletar_categoria(categoria_id: int):
    db = next(get_db())
    categoria = db.query(Categoria).filter(Categoria.id == categoria_id).first()
    if not categoria:
        raise HTTPException(status_code=404, detail="Categoria não encontrada")
    db.delete(categoria)
    db.commit()
    return {"ok": True, "mensagem": "Categoria deletada com sucesso."}

# Rotas de gastos
@app.post("/gastos", response_model=GastoOut)
def criar_gasto(gasto: GastoCreate):
    db = next(get_db())
    categoria = db.query(Categoria).filter(Categoria.id == gasto.categoria_id).first()
    usuario = db.query(Usuario).filter(Usuario.id == gasto.usuario_id).first()
    if not categoria:
        raise HTTPException(status_code=404, detail="Categoria não encontrada")
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    db_gasto = Gasto(**gasto.dict())
    db.add(db_gasto)
    db.commit()
    db.refresh(db_gasto)
    return db_gasto

@app.get("/gastos", response_model=List[GastoOut])
def listar_gastos(usuario_id: int):
    db = next(get_db())
    return db.query(Gasto).filter(Gasto.usuario_id == usuario_id).all()

@app.delete("/gastos/{gasto_id}")
def deletar_gasto(gasto_id: int):
    db = next(get_db())
    gasto = db.query(Gasto).filter(Gasto.id == gasto_id).first()
    if not gasto:
        raise HTTPException(status_code=404, detail="Gasto não encontrado")
    db.delete(gasto)
    db.commit()
    return {"ok": True, "mensagem": "Gasto deletado com sucesso."}

@app.post("/usuarios", response_model=UsuarioOut)
def criar_usuario(usuario: UsuarioCreate):
    db = next(get_db())
    usuario_existente = db.query(Usuario).filter(Usuario.email == usuario.email).first()
    if usuario_existente:
        raise HTTPException(status_code=400, detail="Email já cadastrado")
    senha_hash = pwd_context.hash(usuario.senha)
    db_usuario = Usuario(nome=usuario.nome, email=usuario.email, senha_hash=senha_hash)
    db.add(db_usuario)
    db.commit()
    db.refresh(db_usuario)
    return db_usuario

@app.get("/usuarios", response_model=List[UsuarioOut])
def listar_usuarios():
    db = next(get_db())
    return db.query(Usuario).all()

@app.get("/usuarios/{usuario_id}", response_model=UsuarioOut)
def buscar_usuario(usuario_id: int):
    db = next(get_db())
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    return usuario

@app.delete("/usuarios/{usuario_id}")
def deletar_usuario(usuario_id: int):
    db = next(get_db())
    usuario = db.query(Usuario).filter(Usuario.id == usuario_id).first()
    if not usuario:
        raise HTTPException(status_code=404, detail="Usuário não encontrado")
    db.delete(usuario)
    db.commit()
    return {"ok": True, "mensagem": "Usuário deletado com sucesso"}

@app.post("/login", response_model=UsuarioOut)
def login(request: LoginRequest):
    db = next(get_db())
    usuario = db.query(Usuario).filter(Usuario.email == request.email).first()
    if not usuario or not usuario.verificar_senha(request.senha):
        raise HTTPException(status_code=401, detail="Email ou senha inválidos")
    return usuario

def verificar_senha(self, senha: str) -> bool:
    return pwd_context.verify(senha, self.senha_hash)