/**
 * Página de Detalhes da Empresa
 * Mostra informações completas e permite agendamento
 */
import React, { useState, useEffect } from 'react'
import { useTranslation } from 'react-i18next'
import { useParams, useNavigate } from 'react-router-dom'
import { supabase, Servico } from '../lib/supabase'
import { useAuth } from '../contexts/AuthContext'

interface Empresa {
  id: string
  nome: string
  descricao: string
  categoria: string
  latitude: number
  longitude: number
  avaliacao: number
  created_at?: string
}

export default function EmpresaDetalhes() {
  const { t } = useTranslation()
  const { id: slug } = useParams<{ id: string }>()
  const [empresa, setEmpresa] = useState<Empresa | null>(null)
  const [servicos, setServicos] = useState<Servico[]>([])
  const [loading, setLoading] = useState(true)
  const [servicosLoading, setServicosLoading] = useState(false)
  const [showAgendamento, setShowAgendamento] = useState(false)
  const [servicoSelecionado, setServicoSelecionado] = useState<Servico | null>(null)
  const [dataAgendamento, setDataAgendamento] = useState('')
  const [horarioAgendamento, setHorarioAgendamento] = useState('')
  const [horariosDisponiveis, setHorariosDisponiveis] = useState<{horario: string, disponivel: boolean}[]>([])
  const [agendandoLoading, setAgendandoLoading] = useState(false)
  const [empresaId, setEmpresaId] = useState<string | null>(null)
  const [agendaAberta, setAgendaAberta] = useState(true)
  const { usuario } = useAuth()
  const navigate = useNavigate()

  useEffect(() => {
    if (slug) {
      carregarDados()
    }
  }, [slug])

  const carregarDados = async () => {
    try {
      setLoading(true)
      console.log('🔄 Iniciando carregamento dos dados...')

      // 1. Carregar dados da empresa
      const { data: empresaData, error: empresaError } = await supabase
        .from('empresas')
        .select('*')
        .eq('slug', slug)
        .maybeSingle()

      if (empresaError) {
        console.error('❌ Erro ao carregar empresa:', empresaError)
        setLoading(false)
        return
      }

      console.log('✅ Empresa carregada:', empresaData.nome)
      setEmpresa(empresaData)

      // 2. Carregar serviços e empresa ID para QUALQUER empresa
      if (empresaData.usuario_id) {
        console.log('🎯 Empresa tem usuario_id - carregando serviços...')
        setEmpresaId(empresaData.usuario_id)
        await carregarServicos(empresaData.usuario_id)
        await verificarAgendaAberta(empresaData.usuario_id)
      } else {
        console.log('ℹ️ Empresa sem usuario_id - sem serviços')
        setServicos([])
      }
    } catch (error) {
      console.error('❌ Erro geral:', error)
    } finally {
      setLoading(false)
    }
  }

  const carregarServicos = async (usuarioId: string) => {
    try {
      setServicosLoading(true)
      console.log('🛍️ Carregando serviços para usuario_id:', usuarioId)

      // Buscar serviços da empresa
      const { data: servicosData, error: servicosError } = await supabase
        .from('servicos')
        .select('*')
        .eq('empresa_id', usuarioId)
        .order('nome')

      if (servicosError) {
        console.error('❌ Erro ao carregar serviços:', servicosError)
        setServicos([])
        return
      }

      console.log('✅ Serviços encontrados:', servicosData?.length || 0)
      servicosData?.forEach(s => console.log(`  - ${s.nome}: R$ ${s.preco}`))

      setServicos(servicosData || [])
    } catch (error) {
      console.error('❌ Erro ao carregar serviços:', error)
      setServicos([])
    } finally {
      setServicosLoading(false)
    }
  }

  const verificarAgendaAberta = async (usuarioId: string) => {
    try {
      const { data, error } = await supabase
        .from('usuarios')
        .select('agenda_aberta')
        .eq('id', usuarioId)
        .maybeSingle()

      if (error) throw error
      if (data) {
        setAgendaAberta(data.agenda_aberta ?? true)
      }
    } catch (error) {
      console.error('Erro ao verificar agenda:', error)
      setAgendaAberta(true)
    }
  }

  const carregarHorariosDisponiveis = async (data: string, duracao: number) => {
    if (!empresaId) {
      console.warn('⚠️ empresaId é null - não pode carregar horários')
      return
    }

    try {
      console.log('📅 Carregando horários para:', { empresaId, data, duracao })
      const { data: horarios, error } = await supabase
        .rpc('listar_horarios_disponiveis', {
          p_empresa_id: empresaId,
          p_data: data,
          p_duracao: duracao
        })

      if (error) {
        console.error('❌ Erro na chamada RPC:', error)
        throw error
      }

      console.log('✅ Horários carregados:', horarios?.length || 0)
      setHorariosDisponiveis(horarios || [])
    } catch (error) {
      console.error('Erro ao carregar horários disponíveis:', error)
      setHorariosDisponiveis([])
    }
  }

  useEffect(() => {
    if (dataAgendamento && servicoSelecionado && empresaId) {
      carregarHorariosDisponiveis(dataAgendamento, servicoSelecionado.duracao)
    }
  }, [dataAgendamento, servicoSelecionado, empresaId])

  const iniciarAgendamento = (servico: Servico) => {
    if (!usuario) {
      alert(t('booking.loginRequired'))
      navigate('/login')
      return
    }

    if (usuario.tipo !== 'cliente') {
      alert(t('booking.clientOnly'))
      return
    }

    if (!agendaAberta) {
      alert('Esta empresa não está aceitando agendamentos no momento. Tente novamente mais tarde.')
      return
    }

    setServicoSelecionado(servico)
    setShowAgendamento(true)

    const hoje = new Date()
    const dataMinima = hoje.toISOString().split('T')[0]
    setDataAgendamento(dataMinima)
  }

  const confirmarAgendamento = async () => {
    if (!servicoSelecionado || !dataAgendamento || !horarioAgendamento || !usuario) {
      alert(t('booking.fillFields'))
      return
    }

    try {
      setAgendandoLoading(true)
      console.log('📅 Iniciando processo de agendamento...')

      // Verificar se a data não é no passado
      const dataEscolhida = new Date(dataAgendamento)
      const hoje = new Date()
      hoje.setHours(0, 0, 0, 0)
      
      if (dataEscolhida < hoje) {
        alert(t('booking.pastDate'))
        setAgendandoLoading(false)
        return
      }

      // Buscar o ID da empresa através do serviço selecionado
      console.log('🔍 Buscando empresa através do serviço...')
      console.log('Serviço selecionado:', servicoSelecionado)
      
      const empresaId = servicoSelecionado.empresa_id
      console.log('✅ Empresa ID encontrado:', empresaId)

      // Criar agendamento
      console.log('📝 Criando agendamento no banco de dados...')
      const { data, error: agendamentoError } = await supabase
        .from('agendamentos')
        .insert([
          {
            usuario_id: usuario.id,
            empresa_id: empresaId,
            servico_id: servicoSelecionado.id,
            data: dataAgendamento,
            horario: horarioAgendamento,
            status: 'pendente'
          }
        ])
        .select()

      if (agendamentoError) {
        console.error('❌ Erro ao criar agendamento:', agendamentoError)
        alert(t('booking.error'))
        setAgendandoLoading(false)
        return
      }

      console.log('✅ Agendamento criado com sucesso!', data)
      alert(t('booking.success'))
      
      // Limpar formulário e fechar modal
      setShowAgendamento(false)
      setServicoSelecionado(null)
      setDataAgendamento('')
      setHorarioAgendamento('')
      
      // Redirecionar para dashboard do cliente
      navigate('/cliente/dashboard')
    } catch (error) {
      console.error('❌ Erro inesperado ao criar agendamento:', error)
      alert(t('booking.error'))
    } finally {
      setAgendandoLoading(false)
    }
  }

  const fecharModal = () => {
    setShowAgendamento(false)
    setServicoSelecionado(null)
    setDataAgendamento('')
    setHorarioAgendamento('')
  }

  if (loading) {
    return (
      <div className="loading-container">
        <div className="loading-spinner"></div>
        <p>{t('common.loading')}</p>
      </div>
    )
  }

  if (!empresa) {
    return (
      <div className="error-container">
        <h2>{t('common.error')}</h2>
        <p>{t('company.notFound')}</p>
        <button onClick={() => navigate('/')} className="btn-primary">
          {t('common.back')}
        </button>
      </div>
    )
  }

  return (
    <div className="empresa-detalhes-page">
      <div className="container">
        {/* Cabeçalho da empresa */}
        <div className="empresa-header">
          <div className="empresa-info">
            <h1>{empresa.nome}</h1>
            <p className="categoria">{empresa.categoria}</p>
            <div className="rating">
              ⭐ {t('company.rating', { rating: empresa.avaliacao.toFixed(1) })}
            </div>
            <p className="descricao">{empresa.descricao}</p>
            <p className="localizacao">
              📍 {t('company.location', { lat: empresa.latitude.toFixed(4), lng: empresa.longitude.toFixed(4) })}
            </p>
          </div>
        </div>

        {/* Lista de serviços */}
        <div className="servicos-section">
          <h2>{t('company.services')}</h2>

          {servicosLoading ? (
            <div className="loading-container">
              <div className="loading-spinner"></div>
              <p>{t('common.loading')}</p>
            </div>
          ) : servicos.length === 0 ? (
            <div className="empty-state">
              <p>{t('company.noServices')}</p>
              <p>Esta empresa ainda não cadastrou seus serviços.</p>
            </div>
          ) : (
            <div className="servicos-grid">
              {servicos.map((servico) => (
                <div key={servico.id} className="servico-card">
                  <h3>{servico.nome}</h3>
                  <p className="preco">{t('company.price', { price: servico.preco.toFixed(2) })}</p>
                  <p className="duracao">⏱️ {t('company.duration', { duration: servico.duracao })}</p>

                  <button
                    className="btn-primary"
                    onClick={() => iniciarAgendamento(servico)}
                  >
                    {t('company.schedule')}
                  </button>
                </div>
              ))}
            </div>
          )}
        </div>

        {/* Modal de agendamento */}
        {showAgendamento && servicoSelecionado && (
          <div className="modal-overlay" onClick={fecharModal}>
            <div className="modal" onClick={(e) => e.stopPropagation()}>
              <h3>{t('booking.title', { service: servicoSelecionado.nome })}</h3>
              <p><strong>{t('booking.company')}</strong> {empresa.nome}</p>
              <p><strong>{t('booking.price')}</strong> {t('company.price', { price: servicoSelecionado.preco.toFixed(2) })}</p>
              <p><strong>{t('booking.duration')}</strong> {t('company.duration', { duration: servicoSelecionado.duracao })}</p>
              
              <div className="form-group">
                <label htmlFor="data">{t('booking.date')} *</label>
                <input
                  type="date"
                  id="data"
                  value={dataAgendamento}
                  onChange={(e) => setDataAgendamento(e.target.value)}
                  min={new Date().toISOString().split('T')[0]}
                  max={new Date(Date.now() + 90 * 24 * 60 * 60 * 1000).toISOString().split('T')[0]}
                  required
                />
              </div>

              <div className="form-group">
                <label htmlFor="horario">{t('booking.time')} *</label>
                {!dataAgendamento ? (
                  <p className="helper-text">Selecione uma data primeiro</p>
                ) : horariosDisponiveis.length === 0 ? (
                  <p className="helper-text">Carregando horários...</p>
                ) : (
                  <select
                    id="horario"
                    value={horarioAgendamento}
                    onChange={(e) => setHorarioAgendamento(e.target.value)}
                    required
                  >
                    <option value="">{t('booking.selectTime')}</option>
                    {horariosDisponiveis.map((h) => (
                      <option
                        key={h.horario}
                        value={h.horario}
                        disabled={!h.disponivel}
                      >
                        {h.horario} {!h.disponivel ? '(Indisponível)' : ''}
                      </option>
                    ))}
                  </select>
                )}
              </div>

              <div className="modal-actions">
                <button 
                  className="btn-primary"
                  onClick={confirmarAgendamento}
                  disabled={agendandoLoading || !dataAgendamento || !horarioAgendamento}
                >
                  {agendandoLoading ? t('booking.scheduling') : t('booking.confirm')}
                </button>
                <button 
                  className="btn-secondary"
                  onClick={fecharModal}
                  disabled={agendandoLoading}
                >
                  {t('booking.cancel')}
                </button>
              </div>
            </div>
          </div>
        )}
      </div>
    </div>
  )
}