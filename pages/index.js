import React, { Component } from 'react';
import {Button} from 'semantic-ui-react';
import Layout from '../components/Layout';
import Link from 'next/link'
import web3 from '../ethereum/web3';
import traceabilityContract from "../ethereum/traceabilityContract";

//TODO hacer que los 4 primeros botones esten en un grid 2x2
//Poner el boton de admin abajo del todo y deshabilitarlo si no es admin

class traceabilityIndex extends Component {
    constructor(props) {
        super(props);
        this.state = {
             isAdmin : false
        };
    }

    async componentDidMount () {

    }

    handleAdminClick(e){        
        if(!this.state.isAdmin) e.preventDefault();
    }

    render(){        
        return (
            <Layout>
                <div>
                    <Link href='/shops'>
                        <a>
                            <Button primary fluid>Shops</Button>
                        </a>
                    </Link>
                    <br />
                    <Link href='/producers'>
                        <a>
                            <Button primary fluid>Producers</Button>
                        </a>
                    </Link>
                    <br />
                    <Link href='/transporters'>
                        <a>
                            <Button primary fluid>Transporters</Button>
                        </a>
                    </Link>
                    <br />
                    <Link href='/assets'>
                        <a>
                            <Button primary fluid>Assets</Button>
                        </a>
                    </Link>
                    <br />
                    <Link href='/admin' onClick={this.handleAdminClick}>
                        <a>
                            <Button primary fluid disabled={!this.state.isAdmin}>Admin</Button>
                        </a>
                    </Link>                              
                </div>            
            </Layout>
        );
    }    
}

export default traceabilityIndex;