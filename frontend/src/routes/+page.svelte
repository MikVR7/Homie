<script lang="ts">
	import { onMount } from 'svelte';
	import { homieStore } from '$lib/stores/homieStore';
	import ActivityLog from '$lib/components/ActivityLog.svelte';

	interface ModuleCard {
		id: string;
		title: string;
		icon: string;
		status: 'active' | 'development' | 'planned';
		route: string;
	}

	const modules: ModuleCard[] = [
		{
			id: 'file-organizer',
			title: 'File Organizer',
			icon: '📂',
			status: 'active',
			route: '/file-organizer'
		},
		{
			id: 'media-manager',
			title: 'Media Manager',
			icon: '🎬',
			status: 'planned',
			route: '/media'
		},
		{
			id: 'document-manager',
			title: 'Document Manager',
			icon: '📄',
			status: 'planned',
			route: '/documents'
		},
		{
			id: 'financial-manager',
			title: 'Financial Manager',
			icon: '💰',
			status: 'active',
			route: '/financial'
		}
	];

	onMount(async () => {
		console.log('🏠 Homie Dashboard initialized');
		homieStore.updateStatus('🏠 Homie Dashboard Ready', 'success');
		homieStore.addLogEntry('🚀 Homie ecosystem dashboard loaded', 'success');
	});

	function navigateToModule(module: ModuleCard) {
		if (module.status === 'active') {
			window.location.href = module.route;
		} else {
			homieStore.updateStatus(`${module.icon} ${module.title} - Coming Soon!`, 'warning');
			homieStore.addLogEntry(`📅 ${module.title} is planned for future development`, 'info');
		}
	}

	function getStatusColor(status: string): string {
		switch (status) {
			case 'active': return '#22c55e';
			case 'development': return '#f59e0b';
			case 'planned': return '#6b7280';
			default: return '#6b7280';
		}
	}

	function getStatusText(status: string): string {
		switch (status) {
			case 'active': return 'Available';
			case 'development': return 'In Development';
			case 'planned': return 'Planned';
			default: return 'Unknown';
		}
	}
</script>

<svelte:head>
	<title>🏠 Homie - Smart Home Management</title>
	<meta name="description" content="AI-powered home management ecosystem with file organization, media management, and financial tracking" />
</svelte:head>

<main class="dashboard">
	<div class="dashboard-header">
		<h1>🏠 Homie Dashboard</h1>
	</div>

	<div class="modules-grid">
		{#each modules as module}
			<div 
				class="module-card" 
				class:active={module.status === 'active'}
				class:planned={module.status === 'planned'}
				on:click={() => navigateToModule(module)}
				role="button"
				tabindex="0"
				on:keydown={(e) => e.key === 'Enter' && navigateToModule(module)}
			>
				<span class="module-icon">{module.icon}</span>
				<h3>{module.title}</h3>
				{#if module.status === 'active'}
					<span class="status-badge active">Available</span>
				{:else}
					<span class="status-badge planned">Coming Soon</span>
				{/if}
			</div>
		{/each}
	</div>
	
	<ActivityLog />
</main>

<style>
	:global(body) {
		margin: 0;
		padding: 0;
		background: linear-gradient(135deg, #0f172a 0%, #1e293b 100%);
		color: #e2e8f0;
		min-height: 100vh;
		font-family: 'Inter', -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
	}

	.dashboard {
		max-width: 1200px;
		margin: 0 auto;
		padding: 2rem;
		min-height: 100vh;
	}

	.dashboard-header {
		text-align: center;
		margin-bottom: 2rem;
		padding: 1rem;
	}

	.dashboard-header h1 {
		font-size: 2.5rem;
		margin: 0;
		background: linear-gradient(135deg, #60a5fa, #a78bfa, #f472b6);
		background-clip: text;
		-webkit-background-clip: text;
		-webkit-text-fill-color: transparent;
		font-weight: 700;
	}

	.modules-grid {
		display: grid;
		grid-template-columns: repeat(auto-fit, minmax(250px, 1fr));
		gap: 1.5rem;
		margin-bottom: 2rem;
	}

	.module-card {
		background: rgba(255, 255, 255, 0.05);
		border: 1px solid rgba(255, 255, 255, 0.1);
		border-radius: 12px;
		padding: 1.5rem;
		cursor: pointer;
		transition: all 0.3s ease;
		text-align: center;
	}

	.module-card:hover {
		transform: translateY(-2px);
		box-shadow: 0 8px 25px rgba(0, 0, 0, 0.3);
		border-color: rgba(255, 255, 255, 0.2);
	}

	.module-card.active {
		border-color: rgba(34, 197, 94, 0.5);
	}

	.module-card.planned {
		opacity: 0.6;
	}

	.module-icon {
		font-size: 3rem;
		display: block;
		margin-bottom: 1rem;
	}

	.module-card h3 {
		margin: 0 0 1rem 0;
		font-size: 1.3rem;
		font-weight: 600;
		color: #ffffff;
	}

	.status-badge {
		display: inline-block;
		padding: 0.4rem 1rem;
		border-radius: 20px;
		font-size: 0.8rem;
		font-weight: 500;
	}

	.status-badge.active {
		background: #22c55e;
		color: white;
	}

	.status-badge.planned {
		background: #6b7280;
		color: white;
	}

	@media (max-width: 768px) {
		.dashboard {
			padding: 1rem;
		}

		.dashboard-header h1 {
			font-size: 2.5rem;
		}

		.dashboard-subtitle {
			font-size: 1rem;
		}

		.modules-grid {
			grid-template-columns: 1fr;
			gap: 1.5rem;
		}

		.module-card {
			padding: 1.5rem;
		}

		.module-header {
			flex-direction: column;
			text-align: center;
			gap: 0.5rem;
		}

		.module-icon {
			font-size: 2rem;
		}
	}
</style>
