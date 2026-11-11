<template>
  <div class="min-h-screen bg-gray-100 text-gray-800 flex flex-col">
    <!-- Navbar principal -->
    <header class="bg-white border-b border-gray-200 sticky top-0 z-50">
      <div class="max-w-6xl mx-auto px-4 py-3 flex justify-between items-center">
        <!-- Logo / Marca -->
        <button 
          @click="goHome" 
          class="text-xl font-black text-blue-600 flex items-center gap-2 hover:opacity-80 transition"
        >
          <span class="text-2xl">📖</span>
          <span>MisCromos</span>
        </button>

        <div class="flex items-center gap-3">
          <button 
            v-if="currentView !== 'list'"
            @click="goHome"
            class="text-xs font-bold text-gray-600 hover:text-blue-600 bg-gray-100 px-3 py-2 rounded-lg transition"
          >
            ← Volver al Catálogo
          </button>

          <button 
            @click="openCreate"
            class="bg-blue-600 text-white text-xs font-bold px-3.5 py-2 rounded-lg hover:bg-blue-700 transition"
          >
            + Nueva Colección
          </button>
        </div>
      </div>
    </header>

    <!-- Contenido Principal -->
    <main class="p-4 md:p-8 flex-1">
      <!-- 1. Catálogo de Colecciones (Entrada por defecto) -->
      <CollectionList 
        v-if="currentView === 'list'"
        @select="openAlbum"
        @create="openCreate"
        @edit="openEdit"
      />

      <!-- 2. Grid de Álbum Seleccionado -->
      <AlbumGrid 
        v-else-if="currentView === 'album' && selectedId"
        :collectionId="selectedId"
      />

      <!-- 3. Formulario (Crear / Editar) -->
      <CollectionForm 
        v-else-if="currentView === 'form'"
        :collectionId="editingId"
        @saved="onFormSaved"
        @cancel="goHome"
      />
    </main>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import CollectionList from './components/CollectionList.vue'
import AlbumGrid from './components/AlbumGrid.vue'
import CollectionForm from './components/CollectionForm.vue'

const currentView = ref('list') // 'list', 'album', 'form'
const selectedId = ref(null)
const editingId = ref(null)

const goHome = () => {
  editingId.value = null
  selectedId.value = null
  currentView.value = 'list'
  document.title = 'MisCromos'
}

const openAlbum = (id) => {
  selectedId.value = id
  currentView.value = 'album'
}

const openCreate = () => {
  editingId.value = null
  currentView.value = 'form'
  document.title = 'Nueva Colección - MisCromos'
}

const openEdit = (id) => {
  editingId.value = id
  currentView.value = 'form'
  document.title = 'Editar Colección - MisCromos'
}

const onFormSaved = (id) => {
  selectedId.value = id
  currentView.value = 'album'
}
</script>