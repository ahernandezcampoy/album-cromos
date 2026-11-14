<template>
  <div v-if="loading" class="text-center py-12 text-gray-500 font-semibold">
    Cargando álbum...
  </div>

  <div v-else-if="!collection" class="text-center py-12 text-red-500 font-semibold">
    No se encontró la colección.
  </div>

  <div v-else class="max-w-6xl mx-auto space-y-6 pb-14">
    <!-- Cabecera de la Colección -->
    <div class="bg-white p-6 rounded-2xl shadow-sm border border-gray-100 flex flex-col md:flex-row gap-6 items-center md:items-start">
      <img 
        v-if="collection.image_url" 
        :src="collection.image_url" 
        :alt="collection.title"
        class="w-32 h-44 object-cover rounded-xl shadow border border-gray-200 flex-shrink-0" 
      />
      <div v-else class="w-32 h-44 bg-gray-100 rounded-xl border-2 border-dashed border-gray-300 flex items-center justify-center text-gray-400 font-bold flex-shrink-0 text-center text-xs p-2">
        Sin Portada
      </div>

      <div class="flex-1 text-center md:text-left space-y-2">
        <div class="flex flex-wrap items-center justify-center md:justify-start gap-2">
          <span class="bg-blue-100 text-blue-800 text-xs font-bold px-2.5 py-0.5 rounded-full">
            {{ collection.owner }}
          </span>
          <span class="bg-emerald-100 text-emerald-800 text-xs font-bold px-2.5 py-0.5 rounded-full">
            {{ progressPercentage }}% Completado
          </span>
        </div>
        <h1 class="text-3xl font-extrabold text-gray-800">{{ collection.title }}</h1>
        <p v-if="collection.description" class="text-gray-600 text-sm">{{ collection.description }}</p>

        <!-- Barra de Progreso -->
        <div class="w-full bg-gray-200 rounded-full h-3 mt-4 overflow-hidden">
          <div 
            class="bg-emerald-500 h-3 rounded-full transition-all duration-500" 
            :style="{ width: `${progressPercentage}%` }"
          ></div>
        </div>

        <div class="flex justify-between text-xs text-gray-500 pt-1 font-semibold">
          <span>Conseguidos: {{ acquiredList.length }} / {{ totalStickersCount }}</span>
          <span>Faltan: {{ missingStickers.length }}</span>
        </div>
      </div>
    </div>

    <!-- Barra de Herramientas y Filtros -->
    <div class="bg-white p-4 rounded-xl shadow-sm border border-gray-100 flex flex-wrap items-center justify-between gap-4">
      <div class="flex gap-2">
        <button 
          @click="filter = 'all'" 
          :class="['px-3 py-1.5 text-xs font-bold rounded-lg transition', filter === 'all' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200']"
        >
          Todos ({{ totalStickersCount }})
        </button>
        <button 
          @click="filter = 'missing'" 
          :class="['px-3 py-1.5 text-xs font-bold rounded-lg transition', filter === 'missing' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200']"
        >
          Faltan ({{ missingStickers.length }})
        </button>
        <button 
          @click="filter = 'acquired'" 
          :class="['px-3 py-1.5 text-xs font-bold rounded-lg transition', filter === 'acquired' ? 'bg-blue-600 text-white' : 'bg-gray-100 text-gray-600 hover:bg-gray-200']"
        >
          Tengo ({{ acquiredList.length }})
        </button>
      </div>

      <button 
        @click="copyMissingList"
        class="bg-emerald-600 hover:bg-emerald-700 text-white text-xs font-bold px-4 py-2 rounded-lg shadow flex items-center gap-2 transition active:scale-95"
      >
        <svg class="w-4 h-4" fill="none" stroke="currentColor" viewBox="0 0 24 24"><path stroke-linecap="round" stroke-linejoin="round" stroke-width="2" d="M8 16H6a2 2 0 01-2-2V6a2 2 0 012-2h8a2 2 0 012 2v2m-6 12h8a2 2 0 012-2v-8a2 2 0 01-2-2h-8a2 2 0 01-2 2v8a2 2 0 012 2z"/></svg>
        Copiar Faltas
      </button>
    </div>

    <!-- Secciones del Álbum (Bloques Separados) -->
    <div class="space-y-8">
      <div 
        v-for="section in filteredSections" 
        :key="section.title" 
        class="bg-white p-5 rounded-2xl shadow-sm border border-gray-100 space-y-4"
      >
        <!-- Cabecera del Bloque -->
        <div class="flex justify-between items-center border-b border-gray-100 pb-3">
          <h2 class="text-lg font-bold text-gray-800 flex items-center gap-2">
            <span>{{ section.icon }}</span>
            <span>{{ section.title }}</span>
          </h2>
          <span class="text-xs font-bold text-gray-500 bg-gray-100 px-2.5 py-1 rounded-full">
            {{ section.acquiredCount }} / {{ section.totalCount }} completados
          </span>
        </div>

        <!-- Rejilla de Cromos de la Sección -->
        <div class="grid grid-cols-4 sm:grid-cols-6 md:grid-cols-8 lg:grid-cols-10 gap-2 sm:gap-3">
          <div 
            v-for="sticker in section.stickers" 
            :key="sticker.id"
            @click="toggleSticker(sticker.id)"
            :class="[
              'aspect-[3/4] rounded-xl flex flex-col items-center justify-center p-1 cursor-pointer select-none transition-all transform active:scale-90 border-2 font-mono font-bold text-sm sm:text-base relative overflow-hidden',
              sticker.acquired 
                ? 'bg-emerald-500 border-emerald-600 text-white shadow-md' 
                : 'bg-white border-dashed border-gray-300 text-gray-400 hover:border-blue-400 hover:text-blue-500'
            ]"
          >
            <span>{{ sticker.id }}</span>
            
            <div v-if="sticker.acquired" class="absolute bottom-1 right-1">
              <svg class="w-3.5 h-3.5 text-white opacity-80" fill="currentColor" viewBox="0 0 20 20">
                <path fill-rule="evenodd" d="M16.707 5.293a1 1 0 010 1.414l-8 8a1 1 0 01-1.414 0l-4-4a1 1 0 011.414-1.414L8 12.586l7.293-7.293a1 1 0 011.414 0z" clip-rule="evenodd"/>
              </svg>
            </div>
          </div>
        </div>
      </div>
    </div>

    <!-- Botón flotante Subir Arriba -->
    <button
      v-show="showScrollTop"
      @click="scrollToTop"
      aria-label="Subir arriba"
      title="Subir arriba"
      class="fixed bottom-6 right-6 z-40 bg-blue-600 hover:bg-blue-700 text-white p-3.5 rounded-full shadow-lg transition-all transform hover:scale-105 active:scale-95 cursor-pointer"
    >
      <svg class="w-5 h-5" fill="none" stroke="currentColor" viewBox="0 0 24 24">
        <path stroke-linecap="round" stroke-linejoin="round" stroke-width="2.5" d="M5 15l7-7 7 7" />
      </svg>
    </button>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted, watch } from 'vue'
import { supabase } from '../supabase'

const props = defineProps({
  collectionId: {
    type: String,
    required: true
  }
})

const loading = ref(true)
const collection = ref(null)
const specialGroups = ref([])
const acquiredList = ref([])
const filter = ref('all')

const loadCollectionData = async () => {
  loading.value = true
  try {
    const { data: col, error: colErr } = await supabase
      .from('collections')
      .select('*')
      .eq('id', props.collectionId)
      .single()
    if (colErr) throw colErr
    collection.value = col

    const { data: groups, error: sgErr } = await supabase
      .from('special_groups')
      .select('*')
      .eq('collection_id', props.collectionId)
    if (sgErr) throw sgErr
    specialGroups.value = groups || []

    const { data: prog, error: progErr } = await supabase
      .from('progress')
      .select('acquired')
      .eq('collection_id', props.collectionId)
      .maybeSingle()
    if (progErr) throw progErr
    acquiredList.value = prog?.acquired || []

    // Actualizar el título de la pestaña del navegador
    if (collection.value?.title) {
      document.title = `${collection.value.title} - MisCromos`
    }
  } catch (err) {
    console.error('Error cargando la colección:', err)
  } finally {
    loading.value = false
  }
}

// Estructura de secciones independientes (Regular + 1 por cada Grupo Especial)
const sections = computed(() => {
  if (!collection.value) return []
  const result = []

  // 1. Bloque de Cromos Regulares
  const regularStickers = []
  for (let i = 1; i <= collection.value.total_regular; i++) {
    const idStr = String(i)
    regularStickers.push({
      id: idStr,
      acquired: acquiredList.value.includes(idStr)
    })
  }

  result.push({
    title: 'Cromos Regulares',
    icon: '🎴', // <-- Cambiado de ⚽ a 🎴 (carta/cromo)
    totalCount: collection.value.total_regular,
    acquiredCount: regularStickers.filter(s => s.acquired).length,
    stickers: regularStickers
  })

  // 2. Bloques por cada Grupo Especial (ej. Especiales "X", Especiales "F", etc.)
  specialGroups.value.forEach(group => {
    const groupStickers = []
    for (let i = 1; i <= group.total; i++) {
      const idStr = `${group.prefix}${i}`
      groupStickers.push({
        id: idStr,
        acquired: acquiredList.value.includes(idStr)
      })
    }

    result.push({
      title: `Especiales - Prefijo "${group.prefix}"`,
      icon: '⭐',
      totalCount: group.total,
      acquiredCount: groupStickers.filter(s => s.acquired).length,
      stickers: groupStickers
    })
  })

  return result
})

// Aplicar los filtros globales a cada bloque
const filteredSections = computed(() => {
  return sections.value
    .map(section => {
      let filtered = section.stickers
      if (filter.value === 'missing') filtered = section.stickers.filter(s => !s.acquired)
      if (filter.value === 'acquired') filtered = section.stickers.filter(s => s.acquired)
      return {
        ...section,
        stickers: filtered
      }
    })
    .filter(section => section.stickers.length > 0) // Muestra solo bloques con cromos según el filtro
})

// Todos los cromos en un array plano para métricas globales
const allStickers = computed(() => {
  return sections.value.flatMap(s => s.stickers)
})

const totalStickersCount = computed(() => allStickers.value.length)

const missingStickers = computed(() => {
  return allStickers.value.filter(s => !s.acquired).map(s => s.id)
})

const progressPercentage = computed(() => {
  if (totalStickersCount.value === 0) return 0
  return Math.round((acquiredList.value.length / totalStickersCount.value) * 100)
})

const toggleSticker = async (stickerId) => {
  const exists = acquiredList.value.includes(stickerId)
  if (exists) {
    acquiredList.value = acquiredList.value.filter(id => id !== stickerId)
  } else {
    acquiredList.value.push(stickerId)
  }

  try {
    const { error } = await supabase
      .from('progress')
      .upsert({
        collection_id: props.collectionId,
        acquired: acquiredList.value,
        updated_at: new Date().toISOString()
      })
    if (error) throw error
  } catch (err) {
    console.error('Error actualizando progreso:', err)
  }
}

const copyMissingList = () => {
  if (missingStickers.value.length === 0) {
    alert('¡Felicidades! Ya tienes la colección completa.')
    return
  }
  const text = `Faltas de ${collection.value.title} (${missingStickers.value.length}):\n${missingStickers.value.join(', ')}`
  navigator.clipboard.writeText(text)
  alert('¡Lista de faltas copiada al portapapeles!')
}

onMounted(loadCollectionData)

const showScrollTop = ref(false)

const handleScroll = () => {
  showScrollTop.value = window.scrollY > 300
}

const scrollToTop = () => {
  window.scrollTo({ top: 0, behavior: 'smooth' })
}

onMounted(() => {
  loadCollectionData()
  window.addEventListener('scroll', handleScroll)
})

onUnmounted(() => {
  window.removeEventListener('scroll', handleScroll)
})

watch(() => props.collectionId, loadCollectionData)
</script>